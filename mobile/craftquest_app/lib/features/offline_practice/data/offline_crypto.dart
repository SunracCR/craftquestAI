import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class OfflineCrypto {
  const OfflineCrypto._();

  static Future<List<String>> decryptCorrectAnswerIds({
    required String packageKeyBase64,
    required String correctAnswerBlob,
  }) async {
    final keyBytes = base64Decode(packageKeyBase64);
    final payload = base64Decode(correctAnswerBlob);
    if (payload.length < 28) {
      throw FormatException('Invalid offline correct answer blob.');
    }

    const nonceLength = 12;
    const tagLength = 16;
    final nonce = payload.sublist(0, nonceLength);
    final tag = payload.sublist(nonceLength, nonceLength + tagLength);
    final ciphertext = payload.sublist(nonceLength + tagLength);

    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(keyBytes);
    final secretBox = SecretBox(
      ciphertext,
      nonce: nonce,
      mac: Mac(tag),
    );
    final decrypted = await algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    final decoded = jsonDecode(utf8.decode(decrypted));
    if (decoded is! List) {
      throw FormatException('Expected JSON array of answer option ids.');
    }

    return decoded.map((e) => e.toString()).toList();
  }
}
