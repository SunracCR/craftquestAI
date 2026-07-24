import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class OfflineLocalDatabase {
  OfflineLocalDatabase();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'offline_practice.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE offline_quizzes (
            quiz_id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            content_version TEXT NOT NULL,
            generated_at TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            randomize_questions INTEGER NOT NULL,
            default_randomize_answer_options INTEGER NOT NULL,
            watermark_token TEXT NOT NULL,
            total_bytes INTEGER NOT NULL DEFAULT 0,
            downloaded_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE offline_questions (
            question_id TEXT PRIMARY KEY,
            quiz_id TEXT NOT NULL,
            sort_order INTEGER NOT NULL,
            question_text TEXT NOT NULL,
            question_type TEXT NOT NULL,
            points REAL NOT NULL,
            randomize_answer_options INTEGER NOT NULL,
            scoring_policy TEXT NOT NULL,
            supports_multiple_correct_answers INTEGER NOT NULL,
            question_media_asset_id TEXT,
            correct_answer_blob TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE offline_answer_options (
            answer_option_id TEXT PRIMARY KEY,
            question_id TEXT NOT NULL,
            quiz_id TEXT NOT NULL,
            stable_key TEXT NOT NULL,
            default_sort_order INTEGER NOT NULL,
            answer_text TEXT,
            media_asset_id TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE offline_media_files (
            media_asset_id TEXT NOT NULL,
            quiz_id TEXT NOT NULL,
            local_path TEXT,
            download_url TEXT NOT NULL,
            content_type TEXT,
            file_size_bytes INTEGER,
            status TEXT NOT NULL,
            PRIMARY KEY (media_asset_id, quiz_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE pending_sync_sessions (
            client_session_id TEXT PRIMARY KEY,
            quiz_id TEXT NOT NULL,
            content_version TEXT NOT NULL,
            started_at TEXT NOT NULL,
            finished_at TEXT NOT NULL,
            show_elapsed_timer INTEGER NOT NULL,
            local_score_obtained REAL,
            local_score_possible REAL,
            answers_json TEXT NOT NULL,
            sync_status TEXT NOT NULL,
            sync_attempts INTEGER NOT NULL DEFAULT 0,
            last_sync_attempt_at TEXT,
            server_session_id TEXT,
            sync_error TEXT
          )
        ''');
      },
    );
    return _db!;
  }
}

class OfflineQuizRow {
  OfflineQuizRow({
    required this.quizId,
    required this.title,
    this.description,
    required this.contentVersion,
    required this.generatedAt,
    required this.expiresAt,
    required this.randomizeQuestions,
    required this.defaultRandomizeAnswerOptions,
    required this.watermarkToken,
    required this.totalBytes,
    required this.downloadedAt,
  });

  final String quizId;
  final String title;
  final String? description;
  final String contentVersion;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final bool randomizeQuestions;
  final bool defaultRandomizeAnswerOptions;
  final String watermarkToken;
  final int totalBytes;
  final DateTime downloadedAt;
}

class OfflineQuestionRow {
  OfflineQuestionRow({
    required this.questionId,
    required this.quizId,
    required this.sortOrder,
    required this.questionText,
    required this.questionType,
    required this.points,
    required this.randomizeAnswerOptions,
    required this.scoringPolicy,
    required this.supportsMultipleCorrectAnswers,
    this.questionMediaAssetId,
    required this.correctAnswerBlob,
  });

  final String questionId;
  final String quizId;
  final int sortOrder;
  final String questionText;
  final String questionType;
  final double points;
  final bool randomizeAnswerOptions;
  final String scoringPolicy;
  final bool supportsMultipleCorrectAnswers;
  final String? questionMediaAssetId;
  final String correctAnswerBlob;
}

class OfflineAnswerOptionRow {
  OfflineAnswerOptionRow({
    required this.answerOptionId,
    required this.questionId,
    required this.quizId,
    required this.stableKey,
    required this.defaultSortOrder,
    this.answerText,
    this.mediaAssetId,
  });

  final String answerOptionId;
  final String questionId;
  final String quizId;
  final String stableKey;
  final int defaultSortOrder;
  final String? answerText;
  final String? mediaAssetId;
}

class OfflineMediaFileRow {
  OfflineMediaFileRow({
    required this.mediaAssetId,
    required this.quizId,
    this.localPath,
    required this.downloadUrl,
    this.contentType,
    this.fileSizeBytes,
    required this.status,
  });

  final String mediaAssetId;
  final String quizId;
  final String? localPath;
  final String downloadUrl;
  final String? contentType;
  final int? fileSizeBytes;
  final String status;
}

class PendingSyncSessionRow {
  PendingSyncSessionRow({
    required this.clientSessionId,
    required this.quizId,
    required this.contentVersion,
    required this.startedAt,
    required this.finishedAt,
    required this.showElapsedTimer,
    this.localScoreObtained,
    this.localScorePossible,
    required this.answersJson,
    required this.syncStatus,
    required this.syncAttempts,
    this.lastSyncAttemptAt,
    this.serverSessionId,
    this.syncError,
  });

  final String clientSessionId;
  final String quizId;
  final String contentVersion;
  final DateTime startedAt;
  final DateTime finishedAt;
  final bool showElapsedTimer;
  final double? localScoreObtained;
  final double? localScorePossible;
  final String answersJson;
  final String syncStatus;
  final int syncAttempts;
  final DateTime? lastSyncAttemptAt;
  final String? serverSessionId;
  final String? syncError;
}
