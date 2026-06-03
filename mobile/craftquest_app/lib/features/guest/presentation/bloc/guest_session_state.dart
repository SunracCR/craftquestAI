part of 'guest_session_cubit.dart';

sealed class GuestSessionState {
  const GuestSessionState();

  const factory GuestSessionState.none() = _GuestNone;
  const factory GuestSessionState.loading() = _GuestLoading;
  const factory GuestSessionState.active({required GuestVisitModel visit}) = _GuestActive;
  const factory GuestSessionState.error({required String message}) = _GuestError;
  const factory GuestSessionState.limitReached() = _GuestLimitReached;
}

final class _GuestNone extends GuestSessionState {
  const _GuestNone();
}

final class _GuestLoading extends GuestSessionState {
  const _GuestLoading();
}

final class _GuestActive extends GuestSessionState {
  const _GuestActive({required this.visit});
  final GuestVisitModel visit;
}

final class _GuestError extends GuestSessionState {
  const _GuestError({required this.message});
  final String message;
}

final class _GuestLimitReached extends GuestSessionState {
  const _GuestLimitReached();
}

// Public accessors for pattern matching convenience.
extension GuestSessionStateX on GuestSessionState {
  bool get isNone => this is _GuestNone;
  bool get isLoading => this is _GuestLoading;
  bool get isActive => this is _GuestActive;
  bool get isError => this is _GuestError;
  bool get isLimitReached => this is _GuestLimitReached;

  GuestVisitModel? get visit =>
      this is _GuestActive ? (this as _GuestActive).visit : null;

  String? get errorMessage =>
      this is _GuestError ? (this as _GuestError).message : null;
}
