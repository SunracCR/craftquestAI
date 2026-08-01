import 'dart:convert';

import 'package:craftquest_app/features/auth/data/models/auth_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the last known user profile for offline session restore.
class CachedProfileStore {
  CachedProfileStore({FlutterSecureStorage? storage, Map<String, String>? memory})
      : _storage = storage,
        _memory = memory;

  factory CachedProfileStore.secure() =>
      CachedProfileStore(storage: const FlutterSecureStorage());

  @visibleForTesting
  factory CachedProfileStore.inMemory(Map<String, String> memory) =>
      CachedProfileStore(memory: memory);

  static const _profileKey = 'cached_user_profile';

  final FlutterSecureStorage? _storage;
  final Map<String, String>? _memory;

  Future<void> save(UserProfileModel profile) async {
    final encoded = jsonEncode(profile.toJson());
    if (_memory != null) {
      _memory[_profileKey] = encoded;
      return;
    }
    await _storage!.write(key: _profileKey, value: encoded);
  }

  Future<UserProfileModel?> load() async {
    final raw = _memory != null
        ? _memory[_profileKey]
        : await _storage!.read(key: _profileKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfileModel.fromJson(decoded);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    if (_memory != null) {
      _memory.remove(_profileKey);
      return;
    }
    await _storage!.delete(key: _profileKey);
  }
}
