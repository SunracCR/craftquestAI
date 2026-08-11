import 'dart:convert';

import 'package:craftquest_app/features/offline_practice/data/database/offline_local_database.dart';
import 'package:craftquest_app/features/offline_practice/data/models/offline_models.dart';
import 'package:sqflite/sqflite.dart';

class OfflineSessionCheckpointRepository {
  OfflineSessionCheckpointRepository(this._database);

  final OfflineLocalDatabase _database;

  Future<void> saveCheckpoint({
    required String quizId,
    required String contentVersion,
    required int currentIndex,
    required Map<String, Set<String>> selections,
    required DateTime startedAt,
    required List<String> questionOrder,
    required Map<String, List<String>> answerOrderByQuestion,
  }) async {
    final db = await _database.database;
    final now = DateTime.now().toUtc();
    final selectionsJson = jsonEncode(
      selections.map(
        (questionId, selectedIds) => MapEntry(
          questionId,
          selectedIds.toList(),
        ),
      ),
    );

    await db.insert(
      'offline_session_checkpoints',
      {
        'quiz_id': quizId,
        'content_version': contentVersion,
        'current_index': currentIndex,
        'selections_json': selectionsJson,
        'started_at': startedAt.toUtc().toIso8601String(),
        'updated_at': now.toIso8601String(),
        'question_order_json': jsonEncode(questionOrder),
        'answer_order_json': jsonEncode(answerOrderByQuestion),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<OfflineSessionCheckpointModel?> loadCheckpoint(String quizId) async {
    final db = await _database.database;
    final rows = await db.query(
      'offline_session_checkpoints',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    final decoded = jsonDecode(row['selections_json'] as String)
        as Map<String, dynamic>;
    final selections = decoded.map(
      (questionId, selectedIds) => MapEntry(
        questionId,
        (selectedIds as List<dynamic>).map((id) => id.toString()).toSet(),
      ),
    );

    final questionOrder = (jsonDecode(
              row['question_order_json'] as String? ?? '[]',
            ) as List<dynamic>)
        .map((id) => id.toString())
        .toList();

    final answerOrderDecoded = jsonDecode(
          row['answer_order_json'] as String? ?? '{}',
        ) as Map<String, dynamic>;
    final answerOrderByQuestion = answerOrderDecoded.map(
      (questionId, optionIds) => MapEntry(
        questionId,
        (optionIds as List<dynamic>).map((id) => id.toString()).toList(),
      ),
    );

    return OfflineSessionCheckpointModel(
      quizId: row['quiz_id'] as String,
      contentVersion: row['content_version'] as String,
      currentIndex: row['current_index'] as int,
      selections: selections,
      startedAt: DateTime.parse(row['started_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      questionOrder: questionOrder,
      answerOrderByQuestion: answerOrderByQuestion,
    );
  }

  Future<void> clearCheckpoint(String quizId) async {
    final db = await _database.database;
    await db.delete(
      'offline_session_checkpoints',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
    );
  }
}
