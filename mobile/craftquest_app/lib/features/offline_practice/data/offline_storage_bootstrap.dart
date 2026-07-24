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
      return 'La descarga offline no está disponible en la versión web.';
    }
    return 'La descarga offline no está disponible en esta plataforma.';
  }

  /// Texto del panel cuando la plataforma actual no soporta offline.
  static String get unsupportedPanelMessage {
    if (kIsWeb) {
      return 'Estás en la versión web. Para descargar y practicar sin conexión, '
          'abre CraftQuest en la app de escritorio (Windows) o en tu móvil '
          '(Android/iOS).';
    }
    return 'La descarga offline no está disponible en esta plataforma.';
  }
}
