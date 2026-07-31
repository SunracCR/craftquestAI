import 'dart:convert';

import 'package:craftquest_app/features/offline_practice/data/models/offline_models.dart';
import 'package:cryptography/cryptography.dart';

class OfflineCrypto {
  const OfflineCrypto._();

  static Future<List<String>> decryptCorrectAnswerIds({
    required String packageKeyBase64,
    required String correctAnswerBlob,
  }) async {
    final decoded = await _decryptJson(
      packageKeyBase64: packageKeyBase64,
      blob: correctAnswerBlob,
    );
    if (decoded is! List) {
      throw FormatException('Expected JSON array of answer option ids.');
    }

    return decoded.map((e) => e.toString()).toList();
  }

  static Future<OfflineAnswerKeyModel> decryptAnswerKey({
    required String packageKeyBase64,
    required String answerKeyBlob,
  }) async {
    final decoded = await _decryptJson(
      packageKeyBase64: packageKeyBase64,
      blob: answerKeyBlob,
    );
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Expected JSON object for offline answer key.');
    }

    return OfflineAnswerKeyModel.fromJson(decoded);
  }

  static Future<Object?> _decryptJson({
    required String packageKeyBase64,
    required String blob,
  }) async {
    final keyBytes = base64Decode(packageKeyBase64);
    final payload = base64Decode(blob);
    if (payload.length < 28) {
      throw FormatException('Invalid offline encrypted blob.');
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

    return jsonDecode(utf8.decode(decrypted));
  }
}
