import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Monitors device connectivity for app-wide offline UI.
class NetworkConnectivityService extends ChangeNotifier {
  NetworkConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _applyResults(results);
    await _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen(_applyResults);
  }

  void _applyResults(List<ConnectivityResult> results) {
    final online = _hasNetwork(results);
    if (_isOnline == online) {
      return;
    }
    _isOnline = online;
    notifyListeners();
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return true;
    }
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
