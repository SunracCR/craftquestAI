import 'package:craftquest_app/core/update/app_version_repository.dart';
import 'package:craftquest_app/core/update/app_version_requirement.dart';
import 'package:craftquest_app/core/update/semantic_version.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionCheckResult {
  const AppVersionCheckResult({
    required this.requiresUpdate,
    this.requirement,
  });

  const AppVersionCheckResult.noUpdate() : this(requiresUpdate: false);

  final bool requiresUpdate;
  final AppVersionRequirement? requirement;
}

/// Compara la versión instalada contra el requisito mínimo publicado por el
/// backend (`AppVersionRepository`) para forzar actualización.
class AppVersionService {
  AppVersionService(this._repository);

  final AppVersionRepository _repository;

  Future<AppVersionCheckResult> checkForUpdate() async {
    final platform = _currentPlatform();
    if (platform == null) {
      return const AppVersionCheckResult.noUpdate();
    }

    final requirement = await _repository.getRequirement(platform);
    if (requirement == null) {
      return const AppVersionCheckResult.noUpdate();
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final requiresUpdate = compareSemanticVersions(
          packageInfo.version,
          requirement.minSupportedVersion,
        ) <
        0;

    return AppVersionCheckResult(
      requiresUpdate: requiresUpdate,
      requirement: requirement,
    );
  }

  /// `android` / `ios`, o `null` en web/desktop (no aplica bloqueo ahí).
  static String? _currentPlatform() {
    if (kIsWeb) {
      return null;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return null;
    }
  }
}
