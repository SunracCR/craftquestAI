import 'package:craftquest_app/core/auth/token_storage.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/features/guest/data/guest_token_storage.dart';

/// Cabeceras para `GET /api/media/{id}/file` (JWT o sesión invitado).
abstract final class MediaRequestHeaders {
  static Future<Map<String, String>?> build() async {
    final accessToken = await getIt<TokenStorage>().getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      return {'Authorization': 'Bearer $accessToken'};
    }

    final guest = await getIt<GuestTokenStorage>().load();
    if (guest != null) {
      return {
        'X-Guest-Token': guest.token,
        'X-Guest-Visit-Id': guest.visitId,
      };
    }

    return null;
  }
}
