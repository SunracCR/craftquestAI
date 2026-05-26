import 'dart:async';

import 'package:craftquest_app/core/auth/saved_login_credentials_storage.dart';
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
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
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
    try {
      final profile = await _repository.getProfile();
      emit(AuthAuthenticated(profile));
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
        await _savedLoginStorage.save(
          email: event.email,
          password: event.password,
        );
      } else {
        await _savedLoginStorage.clear();
      }
    } catch (_) {
      // No bloquear la sesión si falla el guardado local.
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await _repository.register(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      emit(AuthAuthenticated(response.user));
    } on DioException catch (e) {
      emit(_loginFailure(_repository.mapError(e)));
    } catch (_) {
      emit(_loginFailure(DioErrorMapper.genericMessage()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logout();
    emit(const AuthUnauthenticated());
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
    try {
      final profile = await _repository.getProfile();
      emit(AuthAuthenticated(profile));
    } catch (_) {
      // Si falla silenciosamente, dejamos el estado actual intacto.
    }
  }
}
