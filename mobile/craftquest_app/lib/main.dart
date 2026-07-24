import 'dart:async';

import 'package:craftquest_app/app.dart';
import 'package:craftquest_app/core/compliance/age_signal_service.dart';
import 'package:craftquest_app/core/compliance/compliance_pref_cache.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/locale/locale_controller.dart';
import 'package:craftquest_app/core/network/dev_http_overrides.dart';
import 'package:craftquest_app/core/network/network_connectivity_service.dart';
import 'package:craftquest_app/core/services/push_notification_service.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_storage_bootstrap.dart';
import 'package:craftquest_app/features/offline_practice/domain/offline_sync_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDevHttpOverrides();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await initializeOfflineStorage();
  configureDependencies();
  await Future.wait([
    getIt<CompliancePrefCache>().warmUp(),
    getIt<LocaleController>().load(),
    getIt<NetworkConnectivityService>().initialize(),
  ]);
  getIt<OfflineSyncManager>().start();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    unawaited(
      getIt<AgeSignalService>().checkAndPersist().then((result) {
        getIt<CompliancePrefCache>().updateParentalBlocked(
          blocked: result.requiresParentalConsent,
          userStatus: result.userStatus,
        );
      }),
    );
  }
  runApp(const CraftQuestApp());
  unawaited(getIt<PushNotificationService>().initializeDeferred());
}
