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
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType.parse(_mimeTypeForFileName(fileName)),
      ),
      if (altText != null && altText.isNotEmpty) 'altText': altText,
    });

    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/media/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return MediaAssetModel.fromJson(response.data!);
  }

  String mapError(DioException error) => DioErrorMapper.map(error);

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
