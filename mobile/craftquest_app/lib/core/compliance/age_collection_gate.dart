import 'dart:async';

import 'package:craftquest_app/core/compliance/age_collection_storage.dart';
import 'package:craftquest_app/core/compliance/age_screen.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Muestra [AgeScreen] una sola vez antes del flujo de autenticación.
class AgeCollectionGate extends StatefulWidget {
  const AgeCollectionGate({super.key, required this.child});

  final Widget child;

  @override
  State<AgeCollectionGate> createState() => _AgeCollectionGateState();
}

class _AgeCollectionGateState extends State<AgeCollectionGate> {
  final _storage = getIt<AgeCollectionStorage>();

  bool _loading = true;
  bool _needsAge = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final collected = await _storage.hasCollectedAge();
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _needsAge = !collected;
    });
  }

  void _onCompleted() {
    setState(() => _needsAge = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_needsAge) {
      return AgeScreen(onCompleted: _onCompleted);
    }

    return widget.child;
  }
}
