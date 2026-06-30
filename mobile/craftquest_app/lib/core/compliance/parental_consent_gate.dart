import 'dart:async';

import 'package:craftquest_app/core/compliance/age_signal_service.dart';
import 'package:craftquest_app/core/compliance/compliance_pref_cache.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/features/compliance/presentation/parental_consent_required_page.dart';
import 'package:flutter/material.dart';

/// Bloquea la app si [AgeSignalService] indica consentimiento parental pendiente.
class ParentalConsentGate extends StatefulWidget {
  const ParentalConsentGate({super.key, required this.child});

  final Widget child;

  @override
  State<ParentalConsentGate> createState() => _ParentalConsentGateState();
}

class _ParentalConsentGateState extends State<ParentalConsentGate>
    with WidgetsBindingObserver {
  final _ageSignals = getIt<AgeSignalService>();
  late final CompliancePrefCache _cache;

  bool _blocked = false;
  String? _userStatus;

  @override
  void initState() {
    super.initState();
    _cache = getIt<CompliancePrefCache>();
    WidgetsBinding.instance.addObserver(this);
    _syncFromCache();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _blocked) {
      unawaited(_refreshFromPlayStore());
    }
  }

  Future<void> _refreshFromPlayStore() async {
    final result = await _ageSignals.checkAndPersist();
    if (!mounted) {
      return;
    }
    _cache.updateParentalBlocked(
      blocked: result.requiresParentalConsent,
      userStatus: result.userStatus,
    );
    setState(() {
      _blocked = result.requiresParentalConsent;
      _userStatus = result.userStatus;
    });
  }

  void _syncFromCache() {
    setState(() {
      _blocked = _cache.parentalBlocked;
      _userStatus = _cache.parentalUserStatus;
    });
  }

  void _onRecheckComplete(bool cleared) {
    if (cleared) {
      _cache.updateParentalBlocked(blocked: false);
      setState(() {
        _blocked = false;
        _userStatus = null;
      });
    } else {
      _syncFromCache();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_blocked) {
      return ParentalConsentRequiredPage(
        userStatus: _userStatus,
        onRecheckComplete: _onRecheckComplete,
      );
    }

    return widget.child;
  }
}
