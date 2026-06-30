import 'dart:async';

import 'package:craftquest_app/core/services/sound_service.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:craftquest_app/features/teacher/data/teacher_dashboard_repository.dart';

/// Background warm-up for first-interaction latency (audio, teacher data).
class AppWarmupService {
  AppWarmupService(
    this._soundService,
    this._teacherDashboardRepository,
    this._prepPlusRepository,
  );

  final SoundService _soundService;
  final TeacherDashboardRepository _teacherDashboardRepository;
  final PrepPlusRepository _prepPlusRepository;
  bool _started = false;

  void start({required bool prefetchTeacherDashboard}) {
    if (_started) {
      return;
    }
    _started = true;
    unawaited(_soundService.warmUp());
    unawaited(_prepPlusRepository.prefetchCategories());
    if (prefetchTeacherDashboard) {
      unawaited(_teacherDashboardRepository.prefetchDashboard());
    }
  }

  void warmSoundOnly() {
    unawaited(_soundService.warmUp());
  }
}
