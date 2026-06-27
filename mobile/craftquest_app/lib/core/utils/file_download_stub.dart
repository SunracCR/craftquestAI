import 'dart:typed_data';

Future<void> downloadFileBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) {
  throw UnsupportedError('downloadFileBytes is only supported on web');
}
