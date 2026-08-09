import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/update/app_version_service.dart';
import 'package:craftquest_app/core/update/force_update_required_page.dart';
import 'package:flutter/material.dart';

/// Bloquea toda la app (antes que auth, antes que cualquier gate de
/// compliance) si [AppVersionService] indica que la versión instalada quedó
/// por debajo de la mínima soportada. Se re-chequea al volver a primer plano
/// por si el requisito cambió (o se resolvió) mientras la app estaba abierta.
class ForceUpdateGate extends StatefulWidget {
  const ForceUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends State<ForceUpdateGate>
    with WidgetsBindingObserver {
  final _service = getIt<AppVersionService>();
  AppVersionCheckResult _result = const AppVersionCheckResult.noUpdate();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_check());
    }
  }

  Future<void> _check() async {
    final result = await _service.checkForUpdate();
    if (!mounted) {
      return;
    }
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final requirement = _result.requirement;
    if (_result.requiresUpdate && requirement != null) {
      return ForceUpdateRequiredPage(requirement: requirement);
    }
    return widget.child;
  }
}
