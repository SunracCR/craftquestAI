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
    on<AuthSessionExpired>(_onSessionExpired);
    on<AuthProfileUpdated>(_onProfileUpdated);
    on<AuthProfileRefreshRequested>(_onProfileRefreshRequested);
  }

  final AuthRepository _repository;
  final SavedLoginCredentialsStorage _savedLoginStorage;

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
      emit(_loginFailure(_repository.mapError(e)));
    } catch (_) {
      emit(_loginFailure(DioErrorMapper.genericMessage()));
    }
  }

  AuthFailure _loginFailure(String message) => AuthFailure(
        message,
        attemptId: DateTime.now().millisecondsSinceEpoch,
      );

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
    // No emitir AuthLoading: _AuthGate reemplazaría toda la app y desmontaría guest/registro.
    if (state is AuthFailure) {
      emit(const AuthUnauthenticated());
    }

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
        emit(_loginFailure(DioErrorMapper.genericMessage()));
        return;
      }

      emit(AuthAuthenticated(response.user));
      _resetSessionExpiredFlag();
      await _savedLoginStorage.clear();
    } on DioException catch (e) {
      emit(_loginFailure(_repository.mapError(e)));
    } catch (_) {
      emit(_loginFailure(DioErrorMapper.genericMessage()));
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
      final response = await _repository.register(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      emit(AuthAuthenticated(response.user));
      _resetSessionExpiredFlag();
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
}
