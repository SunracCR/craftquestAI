import 'dart:convert';

import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/offline_practice/data/database/offline_local_database.dart';
import 'package:craftquest_app/features/offline_practice/data/models/offline_models.dart';
import 'package:sqflite/sqflite.dart';

class OfflineSyncRepository {
  OfflineSyncRepository(this._apiClient, this._database);

  final ApiClient _apiClient;
  final OfflineLocalDatabase _database;

  Future<void> enqueueFinishedSession({
    required String clientSessionId,
    required String quizId,
    required String contentVersion,
    required DateTime startedAt,
    required DateTime finishedAt,
    required bool showElapsedTimer,
    required double localScoreObtained,
    required double localScorePossible,
    required List<OfflineSyncAnswerModel> answers,
  }) async {
    final db = await _database.database;
    await db.insert(
      'pending_sync_sessions',
      {
        'client_session_id': clientSessionId,
        'quiz_id': quizId,
        'content_version': contentVersion,
        'started_at': startedAt.toUtc().toIso8601String(),
        'finished_at': finishedAt.toUtc().toIso8601String(),
        'show_elapsed_timer': showElapsedTimer ? 1 : 0,
        'local_score_obtained': localScoreObtained,
        'local_score_possible': localScorePossible,
        'answers_json': jsonEncode(answers.map((a) => a.toJson()).toList()),
        'sync_status': 'pending',
        'sync_attempts': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PendingSyncSessionRow>> listPendingSessions() async {
    final db = await _database.database;
    final rows = await db.query(
      'pending_sync_sessions',
      where: 'sync_status IN (?, ?)',
      whereArgs: ['pending', 'failed'],
      orderBy: 'finished_at ASC',
    );
    return rows.map(_mapPendingRow).toList();
  }

  Future<OfflineSyncResultModel?> syncSession(PendingSyncSessionRow row) async {
    final db = await _database.database;
    await db.update(
      'pending_sync_sessions',
      {
        'sync_status': 'syncing',
        'sync_attempts': row.syncAttempts + 1,
        'last_sync_attempt_at': DateTime.now().toUtc().toIso8601String(),
        'sync_error': null,
      },
      where: 'client_session_id = ?',
      whereArgs: [row.clientSessionId],
    );

    try {
      final answersJson = jsonDecode(row.answersJson) as List<dynamic>;
      final answers = answersJson
          .map(
            (e) => OfflineSyncAnswerModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();

      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/practice-sessions/offline-sync',
        data: {
          'clientSessionId': row.clientSessionId,
          'quizId': row.quizId,
          'contentVersion': row.contentVersion,
          'startedAt': row.startedAt.toUtc().toIso8601String(),
          'finishedAt': row.finishedAt.toUtc().toIso8601String(),
          'showElapsedTimer': row.showElapsedTimer,
          'localScoreObtained': row.localScoreObtained,
          'localScorePossible': row.localScorePossible,
          'answers': answers.map((a) => a.toJson()).toList(),
        },
      );

      final result = OfflineSyncResultModel.fromJson(response.data!);

      await db.update(
        'pending_sync_sessions',
        {
          'sync_status': 'synced',
          'server_session_id': result.sessionResult.practiceSessionId,
          'sync_error': null,
        },
        where: 'client_session_id = ?',
        whereArgs: [row.clientSessionId],
      );

      return result;
    } catch (error) {
      await db.update(
        'pending_sync_sessions',
        {
          'sync_status': 'failed',
          'sync_error': error.toString(),
        },
        where: 'client_session_id = ?',
        whereArgs: [row.clientSessionId],
      );
      rethrow;
    }
  }

  Future<int> countPendingSessions() async {
    final db = await _database.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM pending_sync_sessions WHERE sync_status IN (?, ?)',
      ['pending', 'failed'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  PendingSyncSessionRow _mapPendingRow(Map<String, Object?> row) {
    return PendingSyncSessionRow(
      clientSessionId: row['client_session_id'] as String,
      quizId: row['quiz_id'] as String,
      contentVersion: row['content_version'] as String,
      startedAt: DateTime.parse(row['started_at'] as String),
      finishedAt: DateTime.parse(row['finished_at'] as String),
      showElapsedTimer: (row['show_elapsed_timer'] as int? ?? 0) == 1,
      localScoreObtained: (row['local_score_obtained'] as num?)?.toDouble(),
      localScorePossible: (row['local_score_possible'] as num?)?.toDouble(),
      answersJson: row['answers_json'] as String,
      syncStatus: row['sync_status'] as String,
      syncAttempts: row['sync_attempts'] as int? ?? 0,
      lastSyncAttemptAt: row['last_sync_attempt_at'] != null
          ? DateTime.parse(row['last_sync_attempt_at'] as String)
          : null,
      serverSessionId: row['server_session_id'] as String?,
      syncError: row['sync_error'] as String?,
    );
  }
}
