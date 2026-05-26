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

    final message = error.message?.toLowerCase() ?? '';
    return message.contains('connection') ||
        message.contains('network') ||
        message.contains('socket') ||
        message.contains('failed host lookup');
  }

  static String map(DioException error, [AppLocalizations? l10n]) {
    final strings = l10n ?? LocalizedMessageHolder.current;

    if (isConnectivityFailure(error)) {
      return strings?.noInternetSnackBarMessage ??
          'Sin conexión a internet. Revisa tu red e inténtalo de nuevo.';
    }

    final statusCode = error.response?.statusCode;
    if (statusCode == 405) {
      return strings?.errorHttpMethodNotAllowed ??
          'El servidor no admite esta operación. Reinicia la API e inténtalo de nuevo.';
    }

    final data = error.response?.data;
    if (data is Map<String, dynamic> && strings != null) {
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

    return genericMessage(l10n);
  }

  static String genericMessage([AppLocalizations? l10n]) {
    final strings = l10n ?? LocalizedMessageHolder.current;
    return strings?.genericRequestErrorMessage ??
        'No se pudo completar la solicitud. Inténtalo de nuevo.';
  }
}
