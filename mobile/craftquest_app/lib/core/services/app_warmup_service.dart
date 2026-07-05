import 'dart:async';

import 'package:craftquest_app/core/services/sound_service.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:craftquest_app/features/teacher/data/teacher_dashboard_repository.dart';

/// Background warm-up for first-interaction latency (audio, billing, teacher data).
class AppWarmupService {
  AppWarmupService(
    this._soundService,
    this._teacherDashboardRepository,
    this._prepPlusRepository,
    this._billingRepository,
  );

  final SoundService _soundService;
  final TeacherDashboardRepository _teacherDashboardRepository;
  final PrepPlusRepository _prepPlusRepository;
  final BillingRepository _billingRepository;
  bool _started = false;

  void start({
    required bool prefetchTeacherDashboard,
    bool deferPrepPrefetch = false,
  }) {
    if (_started) {
      return;
    }
    _started = true;
    unawaited(_soundService.warmUp());
    unawaited(_billingRepository.getMyBilling());
    if (!deferPrepPrefetch) {
      unawaited(_prepPlusRepository.prefetchCategories());
      unawaited(_prepPlusRepository.prefetchMyAccesses());
    }
    if (prefetchTeacherDashboard) {
      unawaited(_teacherDashboardRepository.prefetchDashboard());
    }
  }

  void warmSoundOnly() {
    unawaited(_soundService.warmUp());
  }
}
