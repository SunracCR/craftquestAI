import 'dart:io';

import 'package:flutter/foundation.dart';

/// En debug, confía el certificado de desarrollo de ASP.NET para cargar imágenes con [Image.network].
void configureDevHttpOverrides() {
  if (kIsWeb || !kDebugMode) {
    return;
  }
  HttpOverrides.global = _DevHttpOverrides();
}

final class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) {
      return host == 'localhost' ||
          host == '127.0.0.1' ||
          host == '10.0.2.2';
    };
    return client;
  }
}
