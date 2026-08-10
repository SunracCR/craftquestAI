import 'dart:io';

import 'package:image/image.dart' as img;

/// Quita fondo negro/blanco opaco y guarda PNG con canal alpha real.
Future<void> main(List<String> args) async {
  final input = args.isNotEmpty
      ? args[0]
      : 'assets/images/brand/craftquest_logo.png';
  final bytes = await File(input).readAsBytes();
  final decoded = img.decodePng(bytes);
  if (decoded == null) {
    stderr.writeln('No se pudo decodificar $input');
    exit(1);
  }

  final image = img.Image(
    width: decoded.width,
    height: decoded.height,
    numChannels: 4,
  );

  var cleared = 0;
  for (var y = 0; y < decoded.height; y++) {
    for (var x = 0; x < decoded.width; x++) {
      final pixel = decoded.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      if (_isBakedBackground(r, g, b)) {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
        cleared++;
      } else {
        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
  }

  await File(input).writeAsBytes(img.encodePng(image));
  stdout.writeln('Fondo eliminado en $cleared píxeles → $input');
}

bool _isBakedBackground(int r, int g, int b) {
  if (r == 0 && g == 0 && b == 0) {
    return true;
  }
  final maxChannel = [r, g, b].reduce((a, c) => a > c ? a : c);
  final minChannel = [r, g, b].reduce((a, c) => a < c ? a : c);
  final spread = maxChannel - minChannel;

  // Gris/blanco neutro del export; no toca el gradiente del logo.
  if (spread <= 6 && (maxChannel <= 28 || minChannel >= 240)) {
    return true;
  }
  return false;
}
