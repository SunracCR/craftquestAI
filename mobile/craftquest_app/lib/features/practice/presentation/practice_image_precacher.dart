import 'dart:async';

import 'package:craftquest_app/core/utils/media_request_headers.dart';
import 'package:craftquest_app/features/practice/data/models/practice_models.dart';
import 'package:flutter/widgets.dart';

/// Precarga imágenes de preguntas/opciones para reducir lag al navegar.
abstract final class PracticeImagePrecacher {
  static String? resolveMediaUrl(String baseUrl, String? mediaUrl) {
    if (mediaUrl == null || mediaUrl.isEmpty) {
      return null;
    }
    if (mediaUrl.startsWith('http')) {
      return mediaUrl;
    }
    final normalizedBase = baseUrl.replaceAll(RegExp(r'/$'), '');
    final path = mediaUrl.startsWith('/') ? mediaUrl : '/$mediaUrl';
    return '$normalizedBase$path';
  }

  static void precacheQuestionImages(
    BuildContext context, {
    required String apiBaseUrl,
    PracticeQuestionModel? question,
  }) {
    if (question == null) {
      return;
    }
    unawaited(_precache(context, apiBaseUrl, question));
  }

  static void precacheAdjacentQuestions(
    BuildContext context, {
    required String apiBaseUrl,
    required List<PracticeQuestionModel> questions,
    required int currentIndex,
  }) {
    for (final offset in [-1, 1]) {
      final index = currentIndex + offset;
      if (index >= 0 && index < questions.length) {
        precacheQuestionImages(
          context,
          apiBaseUrl: apiBaseUrl,
          question: questions[index],
        );
      }
    }
  }

  static Future<void> _precache(
    BuildContext context,
    String apiBaseUrl,
    PracticeQuestionModel question,
  ) async {
    final headers = await MediaRequestHeaders.buildCached();
    final urls = <String>[];

    final questionUrl = resolveMediaUrl(apiBaseUrl, question.questionMediaUrl);
    if (questionUrl != null) {
      urls.add(questionUrl);
    }

    for (final answer in question.answers) {
      final url = resolveMediaUrl(apiBaseUrl, answer.mediaUrl);
      if (url != null) {
        urls.add(url);
      }
    }

    if (!context.mounted || urls.isEmpty) {
      return;
    }

    for (final url in urls) {
      try {
        await precacheImage(
          NetworkImage(url, headers: headers ?? const {}),
          context,
        );
      } catch (_) {
        // Best effort: no bloquear la práctica si falla una precarga.
      }
    }
  }
}
