import 'dart:convert';
import 'dart:typed_data';

import 'package:craftquest_app/core/network/api_error_mapper.dart';
import 'package:craftquest_app/core/utils/share_text_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShareTextHelper.resolveShareOrigin', () {
    test('returns provided rect when valid', () {
      const origin = Rect.fromLTWH(10, 20, 100, 40);

      expect(ShareTextHelper.resolveShareOrigin(origin), origin);
    });

    test('returns fallback rect when origin is null', () {
      expect(
        ShareTextHelper.resolveShareOrigin(null),
        const Rect.fromLTWH(0, 0, 48, 48),
      );
    });

    test('returns fallback rect when origin has zero size', () {
      expect(
        ShareTextHelper.resolveShareOrigin(const Rect.fromLTWH(0, 0, 0, 0)),
        const Rect.fromLTWH(0, 0, 48, 48),
      );
    });
  });

  group('ApiErrorMapper.tryParseResponseData', () {
    test('parses JSON bytes from byte responses', () {
      final bytes = utf8.encode(
        '{"errorCode":"QUIZ_PDF_PLAN_REQUIRED","title":"Plan required"}',
      );

      final parsed = ApiErrorMapper.tryParseResponseData(bytes);

      expect(parsed, isNotNull);
      expect(parsed!['errorCode'], 'QUIZ_PDF_PLAN_REQUIRED');
    });

    test('parses Uint8List JSON payloads', () {
      final bytes = Uint8List.fromList(
        utf8.encode('{"errorCode":"QUIZ_PDF_EMPTY"}'),
      );

      final parsed = ApiErrorMapper.tryParseResponseData(bytes);

      expect(parsed, isNotNull);
      expect(parsed!['errorCode'], 'QUIZ_PDF_EMPTY');
    });

    test('returns null for non-json byte payloads', () {
      expect(
        ApiErrorMapper.tryParseResponseData([0x25, 0x50, 0x44, 0x46]),
        isNull,
      );
    });
  });
}
