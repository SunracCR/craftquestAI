import 'dart:io';

import 'package:craftquest_app/core/l10n/localized_message_holder.dart';
import 'package:craftquest_app/core/network/api_error_mapper.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';

abstract final class DioErrorMapper {
  static bool isConnectivityFailure(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return true;
    }

    final underlying = error.error;
    if (underlying is SocketException) {
      return true;
    }
    if (underlying is HttpException) {
      return true;
    }
    final type = underlying.runtimeType.toString().toLowerCase();
    if (type.contains('socket') ||
        type.contains('tls') ||
        type.contains('handshake') ||
        type.contains('certificate')) {
      return true;
    }

    final message = error.message?.toLowerCase() ?? '';
    return message.contains('connection') ||
        message.contains('network') ||
        message.contains('socket') ||
        message.contains('failed host lookup');
  }

  static String map(DioException error, [AppLocalizations? l10n]) {
    final strings = l10n ?? LocalizedMessageHolder.current;

    if (isConnectivityFailure(error)) {
      if (_isLocalDevApi(error.requestOptions.baseUrl)) {
        return strings?.errorDevApiUnreachable ??
            'No se pudo conectar con la API en el teléfono. Ejecuta: adb reverse tcp:7080 tcp:7080';
      }
      return strings?.noInternetSnackBarMessage ??
          'Sin conexión a internet. Revisa tu red e inténtalo de nuevo.';
    }

    final statusCode = error.response?.statusCode;
    final data = _problemDetailsMap(error.response?.data);
    if (data != null && strings != null) {
      final localized = ApiErrorMapper.mapProblemDetails(data, strings);
      if (localized != null && localized.isNotEmpty) {
        return localized;
      }

      final title = data['title'];
      if (title is String && title.isNotEmpty) {
        final mappedTitle = ApiErrorMapper.mapApiTitle(title, strings);
        return mappedTitle ?? title;
      }
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
    }

    if (statusCode == 401) {
      if (_isPublicCredentialAuthPath(error.requestOptions.path)) {
        return strings?.loginInvalidCredentials ??
            'Correo o contraseña incorrectos. Comprueba los datos e inténtalo de nuevo.';
      }
      return strings?.errorSessionExpired ??
          'Tu sesión ha caducado. Vuelve a iniciar sesión e inténtalo de nuevo.';
    }
    if (statusCode == 405) {
      return strings?.errorHttpMethodNotAllowed ??
          'El servidor no admite esta operación. Reinicia la API e inténtalo de nuevo.';
    }
    if (statusCode == 415 && strings != null) {
      return strings.imageUploadInvalidMultipart;
    }

    return genericMessage(l10n);
  }

  static String genericMessage([AppLocalizations? l10n]) {
    final strings = l10n ?? LocalizedMessageHolder.current;
    return strings?.genericRequestErrorMessage ??
        'No se pudo completar la solicitud. Inténtalo de nuevo.';
  }

  static String mapAny(Object error, [AppLocalizations? l10n]) {
    if (error is DioException) {
      return map(error, l10n);
    }
    if (error is FormatException && l10n != null) {
      return l10n.imageUploadInvalidResponse;
    }
    return genericMessage(l10n);
  }

  static bool _isPublicCredentialAuthPath(String path) {
    return path.contains('/api/auth/login') ||
        path.contains('/api/auth/register') ||
        path.contains('/api/auth/google') ||
        path.contains('/api/auth/apple');
  }

  static bool _isLocalDevApi(String baseUrl) {
    final lower = baseUrl.toLowerCase();
    return lower.contains('127.0.0.1') ||
        lower.contains('localhost') ||
        lower.contains('10.0.2.2');
  }

  static Map<String, dynamic>? _problemDetailsMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }
}
