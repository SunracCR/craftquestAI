import 'package:craftquest_app/core/compliance/compliance_pref_cache.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:flutter/foundation.dart';

/// Experiencia restringida para menores de 13 en Android.
abstract final class ChildExperience {
  static bool get isActive {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    final cache = getIt<CompliancePrefCache>();
    if (!cache.isReady) {
      return false;
    }
    return cache.isMinor;
  }
}
