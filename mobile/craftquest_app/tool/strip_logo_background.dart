import 'dart:io';

import 'package:image/image.dart' as img;

/// Quita el fondo negro/gris opaco que algunos exports dejan dentro del PNG.
Future<void> main(List<String> args) async {
  final input = args.isNotEmpty
      ? args[0]
      : 'assets/images/brand/craftquest_logo.png';
  final bytes = await File(input).readAsBytes();
  final image = img.decodePng(bytes);
  if (image == null) {
    stderr.writeln('No se pudo decodificar $input');
    exit(1);
  }

  var cleared = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final a = pixel.a.toInt();
      if (a == 0) {
        continue;
      }
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      if (_isBakedBackground(r, g, b)) {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
        cleared++;
      }
    }
  }

  await File(input).writeAsBytes(img.encodePng(image));
  stdout.writeln('Fondo eliminado en $cleared píxeles → $input');
}

bool _isBakedBackground(int r, int g, int b) {
  final maxChannel = [r, g, b].reduce((a, c) => a > c ? a : c);
  final minChannel = [r, g, b].reduce((a, c) => a < c ? a : c);
  final spread = maxChannel - minChannel;

  // Negro/gris/blanco neutro del export, no colores del gradiente del logo.
  if (spread <= 8 && (maxChannel <= 48 || minChannel >= 240)) {
    return true;
  }
  return false;
}
