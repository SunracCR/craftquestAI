import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/media/data/models/media_models.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';

class MediaRepository {
  MediaRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Sube una imagen usando bytes (compatible con web, móvil y escritorio).
  Future<MediaAssetModel> uploadImage({
    required List<int> bytes,
    required String fileName,
    String? altText,
  }) async {
    try {
      return await _postUpload(
        bytes: bytes,
        fileName: fileName,
        altText: altText,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 &&
          await _apiClient.refreshTokens()) {
        return _postUpload(
          bytes: bytes,
          fileName: fileName,
          altText: altText,
        );
      }
      rethrow;
    }
  }

  Future<MediaAssetModel> _postUpload({
    required List<int> bytes,
    required String fileName,
    String? altText,
  }) async {
    final safeName = _normalizeImageFileName(fileName);
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: safeName,
        contentType: DioMediaType.parse(_mimeTypeForFileName(safeName)),
      ),
      if (altText != null && altText.isNotEmpty) 'altText': altText,
    });

    final response = await _apiClient.dio.post<dynamic>(
      '/api/media/upload',
      data: formData,
      options: Options(
        sendTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 90),
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );

    return MediaAssetModel.fromUploadResponse(response);
  }

  String mapError(DioException error) => DioErrorMapper.map(error);

  /// Asegura extensión permitida por la API (.jpg, .png, etc.).
  static String _normalizeImageFileName(String fileName) {
    var name = fileName.trim().isEmpty ? 'image.jpg' : fileName.trim();
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    var ext = dot > 0 ? name.substring(dot).toLowerCase() : '';

    const allowed = {'.jpg', '.jpeg', '.png', '.webp', '.gif'};
    if (ext == '.heic' || ext == '.heif') {
      ext = '.jpg';
    } else if (!allowed.contains(ext)) {
      ext = '.jpg';
    }

    return '$base$ext';
  }

  static String _mimeTypeForFileName(String fileName) {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    return switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'bmp' => 'image/bmp',
      _ => 'image/jpeg',
    };
  }
}
