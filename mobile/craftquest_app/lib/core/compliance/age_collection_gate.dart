import 'dart:async';

import 'package:craftquest_app/core/compliance/age_collection_controller.dart';
import 'package:craftquest_app/core/compliance/age_collection_policy.dart';
import 'package:craftquest_app/core/compliance/age_screen.dart';
import 'package:craftquest_app/core/compliance/child_experience.dart';
import 'package:craftquest_app/core/compliance/compliance_pref_cache.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/services/push_notification_service.dart';
import 'package:craftquest_app/features/auth/presentation/account_link_launch.dart';
import 'package:flutter/material.dart';

/// Muestra [AgeScreen] una sola vez antes del flujo de autenticación.
class AgeCollectionGate extends StatefulWidget {
  const AgeCollectionGate({super.key, required this.child});

  final Widget child;

  @override
  State<AgeCollectionGate> createState() => _AgeCollectionGateState();
}

class _AgeCollectionGateState extends State<AgeCollectionGate> {
  late final AgeCollectionController _controller;
  late final CompliancePrefCache _cache;

  bool _needsAge = false;

  @override
  void initState() {
    super.initState();
    _controller = getIt<AgeCollectionController>();
    _cache = getIt<CompliancePrefCache>();
    _controller.addListener(_onRecollectionRequested);
    _syncFromCache();
    unawaited(_startPushIfAllowed());
  }

  @override
  void dispose() {
    _controller.removeListener(_onRecollectionRequested);
    super.dispose();
  }

  void _syncFromCache() {
    setState(() => _needsAge = !_cache.ageCollected);
  }

  void _onRecollectionRequested() {
    _syncFromCache();
  }

  void _onCompleted() {
    setState(() => _needsAge = false);
    unawaited(_startPushIfAllowed());
  }

  Future<void> _startPushIfAllowed() async {
    final waitingForAge =
        AgeCollectionPolicy.requiresStartupAgeGate && _needsAge;
    if (waitingForAge) {
      return;
    }
    final push = getIt<PushNotificationService>();
    if (ChildExperience.isActive) {
      await push.stopForChildExperience();
      return;
    }
    await push.initializeDeferred();
  }

  @override
  Widget build(BuildContext context) {
    if (AgeCollectionPolicy.requiresStartupAgeGate &&
        _needsAge &&
        readWebAccountLink() == null) {
      return AgeScreen(onCompleted: _onCompleted);
    }

    return widget.child;
  }
}
