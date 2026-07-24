import 'dart:async';

import 'package:craftquest_app/core/network/network_connectivity_service.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_sync_repository.dart';

class OfflineSyncManager {
  OfflineSyncManager(
    this._syncRepository,
    this._connectivityService,
  );

  final OfflineSyncRepository _syncRepository;
  final NetworkConnectivityService _connectivityService;

  bool _isSyncing = false;
  Timer? _backoffTimer;
  int _backoffAttempt = 0;

  void start() {
    _connectivityService.addListener(_onConnectivityChanged);
    unawaited(syncPendingSessions());
  }

  void dispose() {
    _connectivityService.removeListener(_onConnectivityChanged);
    _backoffTimer?.cancel();
  }

  Future<void> syncPendingSessions() async {
    if (_isSyncing || !_connectivityService.isOnline) {
      return;
    }

    _isSyncing = true;
    try {
      final pending = await _syncRepository.listPendingSessions();
      for (final row in pending) {
        if (!_connectivityService.isOnline) {
          break;
        }
        try {
          await _syncRepository.syncSession(row);
          _backoffAttempt = 0;
        } catch (_) {
          _scheduleBackoffRetry();
          break;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  void _onConnectivityChanged() {
    if (_connectivityService.isOnline) {
      unawaited(syncPendingSessions());
    }
  }

  void _scheduleBackoffRetry() {
    _backoffTimer?.cancel();
    _backoffAttempt = (_backoffAttempt + 1).clamp(1, 6);
    final delaySeconds = 1 << (_backoffAttempt - 1);
    _backoffTimer = Timer(Duration(seconds: delaySeconds), () {
      unawaited(syncPendingSessions());
    });
  }
}
