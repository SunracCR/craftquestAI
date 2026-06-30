import 'package:craftquest_app/core/compliance/age_collection_controller.dart';
import 'package:craftquest_app/core/compliance/age_screen.dart';
import 'package:craftquest_app/core/compliance/compliance_pref_cache.dart';
import 'package:craftquest_app/core/di/injection.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    if (_needsAge) {
      return AgeScreen(onCompleted: _onCompleted);
    }

    return widget.child;
  }
}
