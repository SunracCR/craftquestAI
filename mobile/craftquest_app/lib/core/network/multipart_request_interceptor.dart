import 'package:dio/dio.dart';

/// Quita `Content-Type: application/json` global cuando el body es [FormData],
/// para que Dio genere `multipart/form-data` con boundary correcto.
final class MultipartRequestInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.data is FormData) {
      options.headers.remove(Headers.contentTypeHeader);
      options.headers.remove(Headers.contentLengthHeader);
      options.contentType = null;
    }
    handler.next(options);
  }
}
