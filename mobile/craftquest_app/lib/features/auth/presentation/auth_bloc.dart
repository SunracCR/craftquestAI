import 'dart:async';

import 'package:craftquest_app/core/auth/oauth_sign_in_service.dart';
import 'package:craftquest_app/core/auth/saved_login_credentials_storage.dart';
import 'package:craftquest_app/core/auth/session_expired_notifier.dart';
import 'package:craftquest_app/core/auth/token_storage.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:craftquest_app/features/auth/data/models/auth_models.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository, this._savedLoginStorage) : super(const AuthInitial()) {
    on<AuthSessionChecked>(_onSessionChecked);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthOAuthSignInRequested>(_onOAuthSignInRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthDeleteAccountRequested>(_onDeleteAccountRequested);
    on<AuthSessionExpired>(_onSessionExpired);
    on<AuthProfileUpdated>(_onProfileUpdated);
    on<AuthProfileRefreshRequested>(_onProfileRefreshRequested);
    on<AuthEmailVerified>(_onEmailVerified);
    on<AuthResendVerificationRequested>(_onResendVerificationRequested);
  }

  final AuthRepository _repository;
  final SavedLoginCredentialsStorage _savedLoginStorage;
  int _oauthAttemptSerial = 0;
  bool _oauthSignInInFlight = false;

  Future<void> _onSessionChecked(
    AuthSessionChecked event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final tokenStorage = getIt<TokenStorage>();
    final accessToken = await tokenStorage.getAccessToken();
    final refreshToken = await tokenStorage.getRefreshToken();
    final hasSession = (accessToken != null && accessToken.isNotEmpty) ||
        (refreshToken != null && refreshToken.isNotEmpty);
    if (!hasSession) {
      emit(const AuthUnauthenticated());
      return;
    }

    try {
      final profile = await _repository.getProfile();
      emit(AuthAuthenticated(profile));
      _resetSessionExpiredFlag();
    } catch (_) {
      await _repository.logout();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthFailure) {
      emit(const AuthUnauthenticated());
    }

    try {
      final response = await _repository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(response.user));
      _resetSessionExpiredFlag();
      unawaited(_persistLoginCredentials(event));
    } on DioException catch (e) {
      emit(_loginFailure(_repository.mapError(e), attemptId: event.attemptId, errorCode: _errorCodeFrom(e)));
    } catch (_) {
      emit(_loginFailure(DioErrorMapper.genericMessage(), attemptId: event.attemptId));
    }
  }

  AuthFailure _loginFailure(
    String message, {
    int? attemptId,
    String? errorCode,
  }) =>
      AuthFailure(
        message,
        attemptId: attemptId ?? DateTime.now().millisecondsSinceEpoch,
        errorCode: errorCode,
      );

  String? _errorCodeFrom(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final code = data['errorCode'];
      if (code is String && code.isNotEmpty) {
        return code;
      }
    }
    return null;
  }

  Future<void> _persistLoginCredentials(AuthLoginRequested event) async {
    try {
      if (event.rememberCredentials) {
        await _savedLoginStorage.saveEmail(event.email);
      } else {
        await _savedLoginStorage.clear();
      }
    } catch (_) {
      // No bloquear la sesión si falla el guardado local.
    }
  }

  Future<void> _onOAuthSignInRequested(
    AuthOAuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthAuthenticated || _oauthSignInInFlight) {
      return;
    }

    // No emitir AuthLoading: _AuthGate reemplazaría toda la app y desmontaría guest/registro.
    if (state is AuthFailure) {
      emit(const AuthUnauthenticated());
    }

    _oauthSignInInFlight = true;
    final attempt = ++_oauthAttemptSerial;

    try {
      final AuthResponseModel response;
      if (event.provider == 'google') {
        response = await _repository.loginWithGoogle(idToken: event.idToken);
      } else if (event.provider == 'apple') {
        response = await _repository.loginWithApple(
          idToken: event.idToken,
          email: event.email,
          displayName: event.displayName,
        );
      } else {
        if (attempt != _oauthAttemptSerial) {
          return;
        }
        emit(_loginFailure(DioErrorMapper.genericMessage()));
        return;
      }

      if (attempt != _oauthAttemptSerial) {
        return;
      }

      emit(AuthAuthenticated(response.user));
      _resetSessionExpiredFlag();
      await _savedLoginStorage.clear();
    } on DioException catch (e) {
      if (attempt != _oauthAttemptSerial) {
        return;
      }
      emit(_loginFailure(_repository.mapError(e)));
    } catch (_) {
      if (attempt != _oauthAttemptSerial) {
        return;
      }
      emit(_loginFailure(DioErrorMapper.genericMessage()));
    } finally {
      _oauthSignInInFlight = false;
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthFailure) {
      emit(const AuthUnauthenticated());
    }

    try {
      final result = await _repository.register(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
        dateOfBirth: event.dateOfBirth,
        guardianEmail: event.guardianEmail,
      );
      emit(AuthEmailVerificationPending(
        result.email,
        guardianEmail: result.guardianEmail,
        requiresParentalConsent: result.requiresParentalConsent,
      ));
    } on DioException catch (e) {
      emit(_loginFailure(_repository.mapError(e)));
    } catch (_) {
      emit(_loginFailure(DioErrorMapper.genericMessage()));
    }
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) {
      return;
    }
    await _repository.logout();
    unawaited(OAuthSignInService.clearGoogleSession());
    emit(const AuthUnauthenticated());
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logout();
    unawaited(OAuthSignInService.clearGoogleSession());
    _resetSessionExpiredFlag();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onDeleteAccountRequested(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _repository.deleteAccount();
      unawaited(OAuthSignInService.clearGoogleSession());
      _resetSessionExpiredFlag();
      emit(const AuthUnauthenticated());
    } on DioException catch (e) {
      emit(_loginFailure(_repository.mapError(e)));
    } catch (_) {
      emit(_loginFailure(DioErrorMapper.genericMessage()));
    }
  }

  void _resetSessionExpiredFlag() {
    if (getIt.isRegistered<SessionExpiredNotifier>()) {
      getIt<SessionExpiredNotifier>().reset();
    }
  }

  void _onProfileUpdated(
    AuthProfileUpdated event,
    Emitter<AuthState> emit,
  ) {
    final current = state;
    if (current is AuthAuthenticated) {
      emit(AuthAuthenticated(event.user));
    }
  }

  Future<void> _onProfileRefreshRequested(
    AuthProfileRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) {
      return;
    }
    try {
      final profile = await _repository.refreshSession();
      emit(AuthAuthenticated(profile));
    } catch (_) {
      // Si falla, intentar al menos el perfil con el token actual.
      try {
        final profile = await _repository.getProfile();
        emit(AuthAuthenticated(profile));
      } catch (_) {
        // Mantener el estado actual.
      }
    }
  }

  void _onEmailVerified(
    AuthEmailVerified event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthAuthenticated(event.user));
    _resetSessionExpiredFlag();
  }

  Future<void> _onResendVerificationRequested(
    AuthResendVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _repository.resendVerification(email: event.email);
    } catch (_) {
      // La UI muestra el resultado del reenvío directamente cuando aplica.
    }
  }
}
