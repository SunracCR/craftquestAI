import 'package:craftquest_app/core/auth/token_storage.dart';
import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/offline_practice/data/database/offline_local_database.dart';
import 'package:craftquest_app/features/offline_practice/data/models/offline_models.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_key_storage.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_media_downloader.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_package_repository.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_session_checkpoint_repository.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_sync_repository.dart';
import 'package:craftquest_app/features/offline_practice/presentation/cubit/offline_practice_session_cubit.dart';
import 'package:craftquest_app/features/offline_practice/presentation/cubit/offline_practice_session_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfflinePracticeSessionCubit', () {
    test('load emits offline_package_expired when stored package is expired',
        () async {
      const quizId = 'quiz-expired';
      final expiredQuiz = _buildQuizPackage(
        quizId: quizId,
        expiresAt: DateTime.utc(2020, 1, 1),
      );

      final cubit = OfflinePracticeSessionCubit(
        packageRepository: _FakeOfflinePackageRepository(expiredQuiz),
        syncRepository: _FakeOfflineSyncRepository(),
        checkpointRepository: _FakeOfflineSessionCheckpointRepository(),
        quizId: quizId,
      );

      await cubit.load();

      expect(cubit.state.status, OfflinePracticeSessionStatus.error);
      expect(cubit.state.errorMessage, 'offline_package_expired');
      expect(cubit.state.quiz, isNull);

      await cubit.close();
    });
  });
}

OfflineQuizPackageModel _buildQuizPackage({
  required String quizId,
  required DateTime expiresAt,
}) {
  return OfflineQuizPackageModel(
    quizId: quizId,
    title: 'Expired quiz',
    contentVersion: 'v1',
    generatedAt: DateTime.utc(2020, 1, 1),
    expiresAt: expiresAt,
    packageKeyBase64: 'dGVzdA==',
    randomizeQuestions: false,
    defaultRandomizeAnswerOptions: true,
    watermarkToken: 'wm',
    questions: const [
      OfflinePackageQuestionModel(
        questionId: 'q1',
        sortOrder: 1,
        questionText: 'Question?',
        questionType: 'single_choice',
        points: 1,
        randomizeAnswerOptions: true,
        scoringPolicy: 'strict',
        supportsMultipleCorrectAnswers: false,
        correctAnswerBlob: 'blob',
        answerKeyBlob: 'key-blob',
        answerOptions: [
          OfflinePackageAnswerOptionModel(
            answerOptionId: 'a1',
            stableKey: 'A',
            defaultSortOrder: 1,
            answerText: 'A',
          ),
        ],
      ),
    ],
    mediaAssets: const [],
    entitlements: const OfflineEntitlementsModel(canDownloadOffline: true),
  );
}

class _FakeOfflinePackageRepository extends OfflinePackageRepository {
  _FakeOfflinePackageRepository(this._quiz)
      : super(
          ApiClient(baseUrl: 'http://localhost'),
          OfflineLocalDatabase(),
          OfflineKeyStorage(),
          OfflineMediaDownloader(
            database: OfflineLocalDatabase(),
            tokenStorage: TokenStorage(),
          ),
        );

  final OfflineQuizPackageModel? _quiz;

  @override
  Future<OfflineQuizPackageModel?> loadStoredQuizContent(String quizId) async =>
      _quiz;
}

class _FakeOfflineSyncRepository extends OfflineSyncRepository {
  _FakeOfflineSyncRepository()
      : super(
          ApiClient(baseUrl: 'http://localhost'),
          OfflineLocalDatabase(),
        );
}

class _FakeOfflineSessionCheckpointRepository
    extends OfflineSessionCheckpointRepository {
  _FakeOfflineSessionCheckpointRepository()
      : super(OfflineLocalDatabase());

  @override
  Future<OfflineSessionCheckpointModel?> loadCheckpoint(String quizId) async =>
      null;
}
