import 'dart:convert';

/// Utilidades ligeras para leer la expiración del JWT sin dependencias extra.
abstract final class JwtUtils {
  static DateTime? accessTokenExpiryUtc(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      var payload = parts[1];
      final remainder = payload.length % 4;
      if (remainder > 0) {
        payload += '=' * (4 - remainder);
      }

      final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      final decoded = json.decode(
        utf8.decode(base64.decode(normalized)),
      ) as Map<String, dynamic>;
      final exp = decoded['exp'];
      if (exp is! int) {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    } catch (_) {
      return null;
    }
  }

  static bool shouldRefreshBeforeRequest(
    String token, {
    Duration skew = const Duration(minutes: 2),
  }) {
    final expiry = accessTokenExpiryUtc(token);
    if (expiry == null) {
      return false;
    }
    return DateTime.now().toUtc().isAfter(expiry.subtract(skew));
  }
}
