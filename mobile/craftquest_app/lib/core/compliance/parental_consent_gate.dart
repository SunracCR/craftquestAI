import 'dart:async';

import 'package:craftquest_app/core/compliance/age_signal_service.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
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

  bool _loading = true;
  bool _blocked = false;
  String? _userStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadFromStorage());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _blocked && !_loading) {
      unawaited(_refreshFromPlayStore());
    }
  }

  Future<void> _refreshFromPlayStore() async {
    final result = await _ageSignals.checkAndPersist();
    if (!mounted) {
      return;
    }
    setState(() {
      _blocked = result.requiresParentalConsent;
      _userStatus = result.userStatus;
    });
  }

  Future<void> _loadFromStorage() async {
    final blocked = await _ageSignals.requiresParentalConsent();
    final status = await _ageSignals.lastUserStatus();
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _blocked = blocked;
      _userStatus = status;
    });
  }

  void _onRecheckComplete(bool cleared) {
    if (cleared) {
      setState(() {
        _blocked = false;
        _userStatus = null;
      });
    } else {
      unawaited(_loadFromStorage());
    }
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

    if (_blocked) {
      return ParentalConsentRequiredPage(
        userStatus: _userStatus,
        onRecheckComplete: _onRecheckComplete,
      );
    }

    return widget.child;
  }
}
