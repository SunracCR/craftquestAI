import 'package:craftquest_app/app.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/locale/locale_controller.dart';
import 'package:craftquest_app/core/network/network_connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  configureDependencies();
  await getIt<LocaleController>().load();
  await getIt<NetworkConnectivityService>().initialize();
  runApp(const CraftQuestApp());
}
