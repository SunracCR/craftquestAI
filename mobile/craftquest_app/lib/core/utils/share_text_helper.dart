import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

enum ShareTextOutcome { shared, copied, dismissed }

enum ShareFileOutcome { shared, dismissed, failed }

abstract final class ShareTextHelper {
  /// Calcula el rectángulo de anclaje del popover de compartir.
  /// Debe llamarse en el mismo frame del tap, antes de cualquier `await`.
  static Rect shareOriginFromContext(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect.width > 0 && rect.height > 0) {
        return rect;
      }
    }

    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 48,
      height: 48,
    );
  }

  static bool get needsShareOrigin =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  static Rect resolveShareOrigin(Rect? sharePositionOrigin) {
    if (sharePositionOrigin != null &&
        sharePositionOrigin.width > 0 &&
        sharePositionOrigin.height > 0) {
      return sharePositionOrigin;
    }

    // iOS (incl. iPhone recientes) exige un rect no nulo para UIActivityViewController.
    return const Rect.fromLTWH(0, 0, 48, 48);
  }

  /// Espera a que un overlay (p. ej. diálogo de carga) termine de cerrarse
  /// antes de presentar UIActivityViewController en iOS.
  static Future<void> waitForOverlayDismiss() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  static Future<ShareTextOutcome> shareText(
    String text, {
    Rect? sharePositionOrigin,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(text, 'text', 'must not be empty');
    }

    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: trimmed));
      return ShareTextOutcome.copied;
    }

    final origin = needsShareOrigin
        ? resolveShareOrigin(sharePositionOrigin)
        : sharePositionOrigin;

    try {
      final result = await Share.share(
        trimmed,
        sharePositionOrigin: origin,
      );
      if (result.status == ShareResultStatus.dismissed) {
        return ShareTextOutcome.dismissed;
      }
      return ShareTextOutcome.shared;
    } on PlatformException {
      await Clipboard.setData(ClipboardData(text: trimmed));
      return ShareTextOutcome.copied;
    }
  }

  static Future<ShareFileOutcome> shareFiles({
    required List<XFile> files,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    if (files.isEmpty) {
      throw ArgumentError('files must not be empty');
    }

    final origin = needsShareOrigin
        ? resolveShareOrigin(sharePositionOrigin)
        : sharePositionOrigin;

    try {
      final result = await Share.shareXFiles(
        files,
        subject: subject,
        text: needsShareOrigin ? null : subject,
        sharePositionOrigin: origin,
      );
      if (result.status == ShareResultStatus.dismissed) {
        return ShareFileOutcome.dismissed;
      }
      return ShareFileOutcome.shared;
    } on PlatformException {
      return ShareFileOutcome.failed;
    }
  }
}
