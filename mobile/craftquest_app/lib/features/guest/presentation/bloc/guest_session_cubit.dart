import 'package:craftquest_app/core/guest/anonymous_practice_limit_store.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/features/guest/data/guest_models.dart';
import 'package:craftquest_app/features/guest/data/guest_repository.dart';
import 'package:craftquest_app/features/guest/data/guest_token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'guest_session_state.dart';

class GuestSessionCubit extends Cubit<GuestSessionState> {
  GuestSessionCubit({
    required GuestRepository repository,
    required GuestTokenStorage tokenStorage,
  })  : _repository = repository,
        _tokenStorage = tokenStorage,
        super(const GuestSessionState.none());

  final GuestRepository _repository;
  final GuestTokenStorage _tokenStorage;

  /// Intenta restaurar una visita activa desde almacenamiento seguro.
  Future<void> tryRestore() async {
    final saved = await _tokenStorage.load();
    if (saved == null) return;

    try {
      final visit = await _repository.getVisit(saved.token);
      // Otro flujo pudo borrar el token mientras restaurábamos (p. ej. login/logout).
      final stillSaved = await _tokenStorage.load();
      if (stillSaved == null) return;

      if (visit != null && !visit.isExpired) {
        emit(GuestSessionState.active(visit: visit));
      } else {
        await _tokenStorage.clear();
        emit(const GuestSessionState.none());
      }
    } catch (_) {
      await _tokenStorage.clear();
      emit(const GuestSessionState.none());
    }
  }

  Future<void> enter(String code) async {
    if (!await AnonymousPracticeLimitStore.canRedeemCode()) {
      emit(const GuestSessionState.limitReached());
      return;
    }

    emit(const GuestSessionState.loading());
    try {
      final visit = await _repository.enter(code);
      await AnonymousPracticeLimitStore.recordSuccessfulRedemption();
      await _tokenStorage.save(visitId: visit.guestVisitId, token: visit.token);
      emit(GuestSessionState.active(visit: visit));
    } on DioException catch (e) {
      emit(GuestSessionState.error(message: DioErrorMapper.mapAny(e)));
    } catch (e) {
      emit(GuestSessionState.error(message: DioErrorMapper.mapAny(e)));
    }
  }

  Future<void> leave() async {
    final current = state;
    if (current is! _GuestActive) return;

    try {
      await _repository.leave(
        visitId: current.visit.guestVisitId,
        token: current.visit.token,
      );
    } catch (_) {
      // Best effort: delete locally regardless.
    }

    await _tokenStorage.clear();
    emit(const GuestSessionState.none());
  }

  /// Borra la visita invitada local sin llamar al API (tras login o logout).
  Future<void> clearLocalSession() async {
    await _tokenStorage.clear();
    emit(const GuestSessionState.none());
  }

  /// Tras mostrar el diálogo de límite anónimo, vuelve a estado inicial.
  void acknowledgeLimitReached() {
    if (state.isLimitReached) {
      emit(const GuestSessionState.none());
    }
  }
}
