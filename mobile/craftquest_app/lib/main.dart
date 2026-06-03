import 'package:craftquest_app/app.dart';
import 'package:craftquest_app/core/compliance/age_signal_service.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/locale/locale_controller.dart';
import 'package:craftquest_app/core/network/dev_http_overrides.dart';
import 'package:craftquest_app/core/network/network_connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDevHttpOverrides();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  configureDependencies();
  await getIt<AgeSignalService>().checkAndPersist();
  await getIt<LocaleController>().load();
  await getIt<NetworkConnectivityService>().initialize();
  runApp(const CraftQuestApp());
}
