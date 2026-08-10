import 'package:craftquest_app/core/l10n/localized_message_holder.dart';
import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/update/app_version_requirement.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
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

  /// Variante para el panel admin: solo trata 404 como "sin configurar" y
  /// propaga cualquier otro error (red, 5xx) para mostrarlo en la UI.
  Future<AppVersionRequirement?> getRequirementForAdmin(
    String platform,
  ) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/app-version',
        queryParameters: {'platform': platform},
      );
      final data = response.data;
      return data == null ? null : AppVersionRequirement.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// Requiere rol `content_admin` o `super_admin` en el backend.
  Future<AppVersionRequirement> upsertRequirement(
    String platform,
    Map<String, dynamic> body,
  ) async {
    final response = await _apiClient.dio.put<Map<String, dynamic>>(
      '/api/app-version/$platform',
      data: body,
    );
    return AppVersionRequirement.fromJson(response.data!);
  }

  String mapError(DioException error, [AppLocalizations? l10n]) =>
      DioErrorMapper.map(error, l10n ?? LocalizedMessageHolder.current);
}
