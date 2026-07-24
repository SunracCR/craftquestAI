import 'dart:async';
import 'dart:io';

import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/offline_practice/data/database/offline_local_database.dart';
import 'package:craftquest_app/features/offline_practice/data/models/offline_models.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_key_storage.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_media_downloader.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_paths.dart';
import 'package:sqflite/sqflite.dart';

class OfflinePackageRepository {
  OfflinePackageRepository(
    this._apiClient,
    this._database,
    this._keyStorage,
    this._mediaDownloader,
  );

  final ApiClient _apiClient;
  final OfflineLocalDatabase _database;
  final OfflineKeyStorage _keyStorage;
  final OfflineMediaDownloader _mediaDownloader;

  Future<OfflineQuizPackageModel> fetchPackage(String quizId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/quizzes/$quizId/offline-package',
    );
    return OfflineQuizPackageModel.fromJson(response.data!);
  }

  Future<void> downloadAndPersist({
    required String quizId,
    void Function(DownloadProgressModel progress)? onProgress,
  }) async {
    StreamSubscription<DownloadProgressModel>? subscription;
    if (onProgress != null) {
      subscription = _mediaDownloader.progressStream.listen(onProgress);
    }

    try {
      onProgress?.call(
        DownloadProgressModel(
          quizId: quizId,
          phase: 'package',
          completedUnits: 0,
          totalUnits: 1,
          currentLabel: 'package',
        ),
      );

      final package = await fetchPackage(quizId);
      await _persistPackage(package);

      onProgress?.call(
        DownloadProgressModel(
          quizId: quizId,
          phase: 'package',
          completedUnits: 1,
          totalUnits: 1 + package.mediaAssets.length,
          currentLabel: 'package',
        ),
      );

      if (package.mediaAssets.isNotEmpty) {
        await _mediaDownloader.downloadPendingMedia(quizId);
      }
    } finally {
      await subscription?.cancel();
    }
  }

  Future<void> _persistPackage(OfflineQuizPackageModel package) async {
    await _keyStorage.savePackageKey(
      quizId: package.quizId,
      packageKeyBase64: package.packageKeyBase64,
    );

    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete(
        'offline_answer_options',
        where: 'quiz_id = ?',
        whereArgs: [package.quizId],
      );
      await txn.delete(
        'offline_questions',
        where: 'quiz_id = ?',
        whereArgs: [package.quizId],
      );
      await txn.delete(
        'offline_media_files',
        where: 'quiz_id = ?',
        whereArgs: [package.quizId],
      );
      await txn.delete(
        'offline_quizzes',
        where: 'quiz_id = ?',
        whereArgs: [package.quizId],
      );

      final totalBytes = package.mediaAssets.fold<int>(
        0,
        (sum, asset) => sum + (asset.fileSizeBytes ?? 0),
      );

      await txn.insert('offline_quizzes', {
        'quiz_id': package.quizId,
        'title': package.title,
        'description': package.description,
        'content_version': package.contentVersion,
        'generated_at': package.generatedAt.toUtc().toIso8601String(),
        'expires_at': package.expiresAt.toUtc().toIso8601String(),
        'randomize_questions': package.randomizeQuestions ? 1 : 0,
        'default_randomize_answer_options':
            package.defaultRandomizeAnswerOptions ? 1 : 0,
        'watermark_token': package.watermarkToken,
        'total_bytes': totalBytes,
        'downloaded_at': DateTime.now().toUtc().toIso8601String(),
      });

      for (final question in package.questions) {
        await txn.insert('offline_questions', {
          'question_id': question.questionId,
          'quiz_id': package.quizId,
          'sort_order': question.sortOrder,
          'question_text': question.questionText,
          'question_type': question.questionType,
          'points': question.points,
          'randomize_answer_options': question.randomizeAnswerOptions ? 1 : 0,
          'scoring_policy': question.scoringPolicy,
          'supports_multiple_correct_answers':
              question.supportsMultipleCorrectAnswers ? 1 : 0,
          'question_media_asset_id': question.questionMediaAssetId,
          'correct_answer_blob': question.correctAnswerBlob,
        });

        for (final option in question.answerOptions) {
          await txn.insert('offline_answer_options', {
            'answer_option_id': option.answerOptionId,
            'question_id': question.questionId,
            'quiz_id': package.quizId,
            'stable_key': option.stableKey,
            'default_sort_order': option.defaultSortOrder,
            'answer_text': option.answerText,
            'media_asset_id': option.mediaAssetId,
          });
        }
      }

      for (final media in package.mediaAssets) {
        await txn.insert('offline_media_files', {
          'media_asset_id': media.mediaAssetId,
          'quiz_id': package.quizId,
          'download_url': media.downloadUrl,
          'content_type': media.contentType,
          'file_size_bytes': media.fileSizeBytes,
          'status': 'pending',
        });
      }
    });
  }

  Future<List<OfflineDownloadedQuizSummaryModel>> listDownloadedQuizzes() async {
    final db = await _database.database;
    final quizRows = await db.query('offline_quizzes');
    final summaries = <OfflineDownloadedQuizSummaryModel>[];

    for (final row in quizRows) {
      final quizId = row['quiz_id'] as String;
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM offline_questions WHERE quiz_id = ?',
        [quizId],
      );
      final questionCount = Sqflite.firstIntValue(countResult) ?? 0;
      final mediaRows = await db.query(
        'offline_media_files',
        where: 'quiz_id = ?',
        whereArgs: [quizId],
      );
      final mediaReady =
          mediaRows.where((m) => m['status'] == 'ready').length;

      summaries.add(
        OfflineDownloadedQuizSummaryModel(
          quizId: quizId,
          title: row['title'] as String,
          contentVersion: row['content_version'] as String,
          expiresAt: DateTime.parse(row['expires_at'] as String),
          downloadedAt: DateTime.parse(row['downloaded_at'] as String),
          questionCount: questionCount,
          totalBytes: row['total_bytes'] as int? ?? 0,
          mediaReady: mediaReady,
          mediaTotal: mediaRows.length,
        ),
      );
    }

    summaries.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    return summaries;
  }

  Future<bool> isQuizDownloaded(String quizId) async {
    final db = await _database.database;
    final rows = await db.query(
      'offline_quizzes',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<OfflineQuizPackageModel?> loadStoredQuizContent(String quizId) async {
    final db = await _database.database;
    final quizRows = await db.query(
      'offline_quizzes',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
      limit: 1,
    );
    if (quizRows.isEmpty) {
      return null;
    }
    final quiz = quizRows.first;

    final questionRows = await db.query(
      'offline_questions',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
      orderBy: 'sort_order ASC',
    );
    final optionRows = await db.query(
      'offline_answer_options',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
    );
    final mediaRows = await db.query(
      'offline_media_files',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
    );

    final optionsByQuestion = <String, List<OfflinePackageAnswerOptionModel>>{};
    for (final option in optionRows) {
      final questionId = option['question_id'] as String;
      optionsByQuestion.putIfAbsent(questionId, () => []).add(
            OfflinePackageAnswerOptionModel(
              answerOptionId: option['answer_option_id'] as String,
              stableKey: option['stable_key'] as String,
              defaultSortOrder: option['default_sort_order'] as int,
              answerText: option['answer_text'] as String?,
              mediaAssetId: option['media_asset_id'] as String?,
            ),
          );
    }

    return OfflineQuizPackageModel(
      quizId: quizId,
      title: quiz['title'] as String,
      description: quiz['description'] as String?,
      contentVersion: quiz['content_version'] as String,
      generatedAt: DateTime.parse(quiz['generated_at'] as String),
      expiresAt: DateTime.parse(quiz['expires_at'] as String),
      packageKeyBase64: await _keyStorage.readPackageKey(quizId) ?? '',
      randomizeQuestions: (quiz['randomize_questions'] as int? ?? 0) == 1,
      defaultRandomizeAnswerOptions:
          (quiz['default_randomize_answer_options'] as int? ?? 1) == 1,
      watermarkToken: quiz['watermark_token'] as String,
      questions: questionRows
          .map(
            (q) => OfflinePackageQuestionModel(
              questionId: q['question_id'] as String,
              sortOrder: q['sort_order'] as int,
              questionText: q['question_text'] as String,
              questionType: q['question_type'] as String,
              points: (q['points'] as num).toDouble(),
              randomizeAnswerOptions:
                  (q['randomize_answer_options'] as int? ?? 1) == 1,
              scoringPolicy: q['scoring_policy'] as String? ?? 'strict',
              supportsMultipleCorrectAnswers:
                  (q['supports_multiple_correct_answers'] as int? ?? 0) == 1,
              questionMediaAssetId: q['question_media_asset_id'] as String?,
              correctAnswerBlob: q['correct_answer_blob'] as String,
              answerOptions:
                  optionsByQuestion[q['question_id'] as String] ?? const [],
            ),
          )
          .toList(),
      mediaAssets: mediaRows
          .map(
            (m) => OfflinePackageMediaAssetModel(
              mediaAssetId: m['media_asset_id'] as String,
              downloadUrl: m['download_url'] as String,
              contentType: m['content_type'] as String?,
              fileSizeBytes: m['file_size_bytes'] as int?,
            ),
          )
          .toList(),
      entitlements: const OfflineEntitlementsModel(canDownloadOffline: true),
    );
  }

  Future<String?> resolveLocalMediaPath({
    required String quizId,
    required String mediaAssetId,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'offline_media_files',
      where: 'quiz_id = ? AND media_asset_id = ?',
      whereArgs: [quizId, mediaAssetId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final path = rows.first['local_path'] as String?;
    if (path == null || path.isEmpty) {
      return null;
    }
    return File(path).existsSync() ? path : null;
  }

  Future<void> deleteDownloadedQuiz(String quizId) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete(
        'pending_sync_sessions',
        where: 'quiz_id = ?',
        whereArgs: [quizId],
      );
      await txn.delete(
        'offline_answer_options',
        where: 'quiz_id = ?',
        whereArgs: [quizId],
      );
      await txn.delete(
        'offline_questions',
        where: 'quiz_id = ?',
        whereArgs: [quizId],
      );
      await txn.delete(
        'offline_media_files',
        where: 'quiz_id = ?',
        whereArgs: [quizId],
      );
      await txn.delete(
        'offline_quizzes',
        where: 'quiz_id = ?',
        whereArgs: [quizId],
      );
    });

    await _keyStorage.deletePackageKey(quizId);

    final mediaDir = Directory(await offlineMediaDirectoryPath(quizId));
    if (mediaDir.existsSync()) {
      await mediaDir.delete(recursive: true);
    }
  }

  Future<int> countDownloadedQuizzes() async {
    final db = await _database.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM offline_quizzes');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> totalStorageBytes() async {
    final db = await _database.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(total_bytes), 0) AS total FROM offline_quizzes',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
