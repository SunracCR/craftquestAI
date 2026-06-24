part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthSessionChecked extends AuthEvent {
  const AuthSessionChecked();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.email,
    required this.password,
    this.rememberCredentials = false,
    this.attemptId,
  });

  final String email;
  final String password;
  final bool rememberCredentials;
  final int? attemptId;

  @override
  List<Object?> get props => [email, password, rememberCredentials, attemptId];
}

class AuthOAuthSignInRequested extends AuthEvent {
  const AuthOAuthSignInRequested({
    required this.provider,
    required this.idToken,
    this.email,
    this.displayName,
  });

  final String provider;
  final String idToken;
  final String? email;
  final String? displayName;

  @override
  List<Object?> get props => [provider, idToken, email, displayName];
}

class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    this.displayName,
  });

  final String email;
  final String password;
  final String? displayName;

  @override
  List<Object?> get props => [email, password, displayName];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Sesión invalidada (p. ej. refresh token expirado); cierra sesión en la app.
class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}

class AuthProfileUpdated extends AuthEvent {
  const AuthProfileUpdated(this.user);

  final UserProfileModel user;

  @override
  List<Object?> get props => [user];
}

/// Recarga el perfil del usuario desde la API (útil tras compra/cancelación de plan).
class AuthProfileRefreshRequested extends AuthEvent {
  const AuthProfileRefreshRequested();
}

class AuthEmailVerified extends AuthEvent {
  const AuthEmailVerified(this.user);

  final UserProfileModel user;

  @override
  List<Object?> get props => [user];
}

class AuthResendVerificationRequested extends AuthEvent {
  const AuthResendVerificationRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}
