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
  });

  final String email;
  final String password;
  final bool rememberCredentials;

  @override
  List<Object?> get props => [email, password, rememberCredentials];
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
