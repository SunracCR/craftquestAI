import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Icono de compartir según plataforma: iOS/macOS usa [Icons.ios_share_rounded],
/// Android y web usan [Icons.share_rounded].
abstract final class ShareIcons {
  static bool get _isApplePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static IconData adaptive({bool outlined = false}) {
    if (_isApplePlatform) {
      return outlined ? Icons.ios_share_outlined : Icons.ios_share_rounded;
    }
    return outlined ? Icons.share_outlined : Icons.share_rounded;
  }

  static Widget adaptiveIcon({
    Key? key,
    double? size,
    Color? color,
    bool outlined = false,
  }) {
    return Icon(
      adaptive(outlined: outlined),
      key: key,
      size: size,
      color: color,
    );
  }
}
