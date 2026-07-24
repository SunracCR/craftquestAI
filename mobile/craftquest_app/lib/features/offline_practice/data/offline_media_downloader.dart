import 'dart:async';
import 'dart:io';

import 'package:craftquest_app/core/auth/token_storage.dart';
import 'package:craftquest_app/core/utils/media_url_resolver.dart';
import 'package:craftquest_app/features/offline_practice/data/database/offline_local_database.dart';
import 'package:craftquest_app/features/offline_practice/data/models/offline_models.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_paths.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

class OfflineMediaDownloader {
  OfflineMediaDownloader({
    required OfflineLocalDatabase database,
    required TokenStorage tokenStorage,
    Dio? dio,
    this.maxConcurrentDownloads = 3,
  })  : _database = database,
        _tokenStorage = tokenStorage,
        _dio = dio ?? Dio();

  final OfflineLocalDatabase _database;
  final TokenStorage _tokenStorage;
  final Dio _dio;
  final int maxConcurrentDownloads;

  final _progressController = StreamController<DownloadProgressModel>.broadcast();
  Stream<DownloadProgressModel> get progressStream => _progressController.stream;

  final Map<String, bool> _cancelTokens = {};

  void cancelDownload(String quizId) {
    _cancelTokens[quizId] = true;
  }

  Future<void> downloadPendingMedia(String quizId) async {
    _cancelTokens[quizId] = false;
    final db = await _database.database;
    final pending = await db.query(
      'offline_media_files',
      where: 'quiz_id = ? AND status != ?',
      whereArgs: [quizId, 'ready'],
    );

    if (pending.isEmpty) {
      return;
    }

    final mediaDir = await _mediaDirectoryForQuiz(quizId);
    var completed = 0;
    final total = pending.length;

    _emitProgress(
      quizId: quizId,
      phase: 'media',
      completed: completed,
      total: total,
    );

    for (var i = 0; i < pending.length; i += maxConcurrentDownloads) {
      if (_cancelTokens[quizId] == true) {
        break;
      }

      final batch = pending.skip(i).take(maxConcurrentDownloads).toList();
      await Future.wait(
        batch.map((item) async {
          if (_cancelTokens[quizId] == true) {
            return;
          }

          final mediaAssetId = item['media_asset_id'] as String;
          await db.update(
            'offline_media_files',
            {'status': 'downloading'},
            where: 'quiz_id = ? AND media_asset_id = ?',
            whereArgs: [quizId, mediaAssetId],
          );

          try {
            final localPath = p.join(
              mediaDir.path,
              '$mediaAssetId${_extensionForContentType(item['content_type'] as String?)}',
            );
            final url =
                MediaUrlResolver.resolveAbsolute(item['download_url'] as String);
            final headers = await _authHeaders();
            await _dio.download(
              url,
              localPath,
              options: Options(headers: headers),
            );

            await db.update(
              'offline_media_files',
              {
                'local_path': localPath,
                'status': 'ready',
              },
              where: 'quiz_id = ? AND media_asset_id = ?',
              whereArgs: [quizId, mediaAssetId],
            );
          } catch (_) {
            await db.update(
              'offline_media_files',
              {'status': 'failed'},
              where: 'quiz_id = ? AND media_asset_id = ?',
              whereArgs: [quizId, mediaAssetId],
            );
          } finally {
            completed++;
            _emitProgress(
              quizId: quizId,
              phase: 'media',
              completed: completed,
              total: total,
              currentLabel: mediaAssetId,
            );
          }
        }),
      );
    }
  }

  Future<Directory> _mediaDirectoryForQuiz(String quizId) async {
    final dir = Directory(await offlineMediaDirectoryPath(quizId));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Map<String, String>?> _authHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    return {'Authorization': 'Bearer $token'};
  }

  String _extensionForContentType(String? contentType) {
    return switch (contentType) {
      'image/png' => '.png',
      'image/jpeg' => '.jpg',
      'image/webp' => '.webp',
      'image/gif' => '.gif',
      _ => '.bin',
    };
  }

  void _emitProgress({
    required String quizId,
    required String phase,
    required int completed,
    required int total,
    String? currentLabel,
  }) {
    if (_progressController.isClosed) {
      return;
    }
    _progressController.add(
      DownloadProgressModel(
        quizId: quizId,
        phase: phase,
        completedUnits: completed,
        totalUnits: total,
        currentLabel: currentLabel,
        isCancelled: _cancelTokens[quizId] == true,
      ),
    );
  }

  void dispose() {
    _progressController.close();
  }
}
