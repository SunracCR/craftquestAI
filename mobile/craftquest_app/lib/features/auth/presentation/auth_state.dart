part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final UserProfileModel user;

  @override
  List<Object?> get props => [user];
}

class AuthFailure extends AuthState {
  const AuthFailure(this.message, {required this.attemptId});

  final String message;

  /// Evita que Bloc ignore fallos repetidos con el mismo mensaje.
  final int attemptId;

  @override
  List<Object?> get props => [message, attemptId];
}
