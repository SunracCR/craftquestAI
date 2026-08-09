import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/core/update/app_version_requirement.dart';
import 'package:dio/dio.dart';

/// Consulta el requisito de versión mínima por plataforma. Endpoint público
/// (`AllowAnonymous`): debe responder aunque no haya sesión o el token haya
/// vencido, porque el chequeo corre antes/independiente del login.
class AppVersionRepository {
  AppVersionRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Devuelve `null` ante cualquier error (sin conexión, 404, timeout, etc.):
  /// nunca debe impedir el arranque de la app por una falla de red.
  Future<AppVersionRequirement?> getRequirement(String platform) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/app-version',
        queryParameters: {'platform': platform},
      );
      final data = response.data;
      if (data == null) {
        return null;
      }
      return AppVersionRequirement.fromJson(data);
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
