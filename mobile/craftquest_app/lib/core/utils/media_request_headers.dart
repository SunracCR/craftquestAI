import 'package:craftquest_app/core/auth/token_storage.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/features/guest/data/guest_token_storage.dart';

/// Cabeceras para `GET /api/media/{id}/file` (JWT o sesión invitado).
abstract final class MediaRequestHeaders {
  static Map<String, String>? _cached;
  static Future<Map<String, String>?>? _inFlight;

  /// Limpia la caché en memoria (login, logout, refresh de token, cambio de invitado).
  static void invalidate() {
    _cached = null;
    _inFlight = null;
  }

  /// Valor cacheado sin I/O, o `null` si aún no se resolvió.
  static Map<String, String>? get cachedOrNull => _cached;

  /// Devuelve cabeceras cacheadas o las resuelve una sola vez hasta [invalidate].
  static Future<Map<String, String>?> buildCached() async {
    if (_cached != null) {
      return _cached;
    }

    _inFlight ??= build().whenComplete(() {
      _inFlight = null;
    });

    return _inFlight!;
  }

  static Future<Map<String, String>?> build() async {
    final accessToken = await getIt<TokenStorage>().getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      _cached = {'Authorization': 'Bearer $accessToken'};
      return _cached;
    }

    final guest = await getIt<GuestTokenStorage>().load();
    if (guest != null) {
      _cached = {
        'X-Guest-Token': guest.token,
        'X-Guest-Visit-Id': guest.visitId,
      };
      return _cached;
    }

    _cached = null;
    return null;
  }
}
