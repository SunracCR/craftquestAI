import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Inicializa SQLite/path en desktop (Windows/macOS/Linux).
Future<void> initializeOfflineStorage() async {
  if (kIsWeb) {
    return;
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

abstract final class OfflinePlatformSupport {
  static bool get isSupported {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isWindows ||
        Platform.isLinux ||
        Platform.isMacOS;
  }

  static String get unsupportedMessage {
    if (kIsWeb) {
      return 'La descarga offline está disponible en la app móvil (Android/iOS).';
    }
    return 'La descarga offline no está disponible en esta plataforma.';
  }
}
