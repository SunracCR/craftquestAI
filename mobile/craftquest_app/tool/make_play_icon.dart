import 'dart:io';

import 'package:image/image.dart' as img;

/// Genera el ícono de Play Store 512x512 con el mismo fondo que Android (#1A2228).
Future<void> main() async {
  const srcPath = 'assets/images/brand/craftquest_logo.png';
  const outPath = 'store/play_icon_512.png';
  const size = 512;
  const insetRatio = 0.16;
  const bgR = 0x1A;
  const bgG = 0x22;
  const bgB = 0x28;

  final bytes = await File(srcPath).readAsBytes();
  final decoded = img.decodePng(bytes);
  if (decoded == null) {
    stderr.writeln('No se pudo leer $srcPath');
    exit(1);
  }

  final logo = img.Image(width: decoded.width, height: decoded.height, numChannels: 4);
  for (final pixel in decoded) {
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();
    final a = pixel.a.toInt();
    final maxC = [r, g, b].reduce((x, y) => x > y ? x : y);
    final minC = [r, g, b].reduce((x, y) => x < y ? x : y);
    final isBg = a < 16 || (maxC <= 28 && (maxC - minC) <= 8);
    logo.setPixelRgba(pixel.x, pixel.y, r, g, b, isBg ? 0 : 255);
  }

  final canvas = img.Image(width: size, height: size, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(bgR, bgG, bgB, 255));

  final inset = (size * insetRatio).round();
  final destSize = size - inset * 2;
  final scaled = img.copyResize(
    logo,
    width: destSize,
    height: destSize,
    interpolation: img.Interpolation.cubic,
  );
  img.compositeImage(canvas, scaled, dstX: inset, dstY: inset);

  await Directory('store').create(recursive: true);
  await File(outPath).writeAsBytes(img.encodePng(canvas));
  stdout.writeln('OK $outPath (${size}x$size, fondo #1A2228)');
}
