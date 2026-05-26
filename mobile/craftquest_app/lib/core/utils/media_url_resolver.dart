import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/api_client.dart';

/// Construye la URL pública de un media asset (misma ruta que la API).
abstract final class MediaUrlResolver {
  static const _publicPathPrefix = '/api/media';

  static String? resolve(String? mediaAssetId) {
    if (mediaAssetId == null || mediaAssetId.isEmpty) {
      return null;
    }
    final base =
        getIt<ApiClient>().dio.options.baseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base$_publicPathPrefix/$mediaAssetId/file';
  }

  static String resolveAbsolute(String url) {
    if (url.startsWith('http')) return url;
    final base =
        getIt<ApiClient>().dio.options.baseUrl.replaceAll(RegExp(r'/$'), '');
    final path = url.startsWith('/') ? url : '/$url';
    return '$base$path';
  }
}
