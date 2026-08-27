import 'package:craftquest_app/core/network/network_connectivity_service.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_package_repository.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';

/// Aligns local offline package expiry with current Prep+ access when online.
class OfflinePrepAccessReconciler {
  OfflinePrepAccessReconciler(
    this._prepPlusRepository,
    this._connectivityService,
    this._packageRepository,
  );

  final PrepPlusRepository _prepPlusRepository;
  final NetworkConnectivityService _connectivityService;
  final OfflinePackageRepository _packageRepository;

  Future<bool> isOfflinePracticeBlocked(String quizId) async {
    final quiz = await _packageRepository.loadStoredQuizContent(quizId);
    if (quiz == null) {
      return true;
    }

    final effectiveExpiresAt = await resolveEffectiveExpiresAt(
      quizId: quizId,
      localExpiresAt: quiz.expiresAt.toUtc(),
    );

    return effectiveExpiresAt.isBefore(DateTime.now().toUtc());
  }

  Future<void> reconcileAllDownloadedQuizzes() async {
    if (!_connectivityService.isOnline) {
      return;
    }

    final downloads = await _packageRepository.listDownloadedQuizzes();
    for (final item in downloads) {
      await resolveEffectiveExpiresAt(
        quizId: item.quizId,
        localExpiresAt: item.expiresAt.toUtc(),
      );
    }
  }

  Future<DateTime> resolveEffectiveExpiresAt({
    required String quizId,
    required DateTime localExpiresAt,
  }) async {
    var effectiveExpiresAt = localExpiresAt;

    if (!_connectivityService.isOnline) {
      return effectiveExpiresAt;
    }

    final prepAccess = await _findPrepAccessForQuiz(quizId);
    if (prepAccess == null || prepAccess.isLifetimeAccess) {
      return effectiveExpiresAt;
    }

    if (!prepAccess.canPractice) {
      final accessExpiresAt = prepAccess.expiresAt?.toUtc() ?? DateTime.now().toUtc();
      effectiveExpiresAt = _earlier(accessExpiresAt, effectiveExpiresAt);
    } else if (prepAccess.expiresAt != null) {
      effectiveExpiresAt = _earlier(prepAccess.expiresAt!.toUtc(), effectiveExpiresAt);
    }

    if (effectiveExpiresAt.isBefore(localExpiresAt)) {
      await _packageRepository.patchExpiresAt(quizId, effectiveExpiresAt);
    }

    return effectiveExpiresAt;
  }

  Future<PrepMyAccessItemModel?> _findPrepAccessForQuiz(String quizId) async {
    try {
      final accesses = await _prepPlusRepository.getMyAccesses(forceRefresh: true);
      for (final item in [...accesses.active, ...accesses.expired]) {
        if (item.quizId == quizId) {
          return item;
        }
      }
    } catch (_) {
      // Fall back to local expiry when Prep+ status cannot be refreshed.
    }

    return null;
  }

  DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}
