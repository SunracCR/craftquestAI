import 'package:craftquest_app/core/auth/token_storage.dart';
import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/core/network/network_connectivity_service.dart';
import 'package:craftquest_app/features/offline_practice/data/database/offline_local_database.dart';
import 'package:craftquest_app/features/offline_practice/data/models/offline_models.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_key_storage.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_media_downloader.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_package_repository.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_session_checkpoint_repository.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_sync_repository.dart';
import 'package:craftquest_app/features/offline_practice/domain/offline_prep_access_reconciler.dart';
import 'package:craftquest_app/features/offline_practice/presentation/cubit/offline_practice_session_cubit.dart';
import 'package:craftquest_app/features/offline_practice/presentation/cubit/offline_practice_session_state.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
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
      final packageRepository = _FakeOfflinePackageRepository(expiredQuiz);

      final cubit = OfflinePracticeSessionCubit(
        packageRepository: packageRepository,
        syncRepository: _FakeOfflineSyncRepository(),
        checkpointRepository: _FakeOfflineSessionCheckpointRepository(),
        accessReconciler: OfflinePrepAccessReconciler(
          _FakePrepPlusRepository(),
          _FakeConnectivityService(isOnline: false),
          packageRepository,
        ),
        quizId: quizId,
      );

      await cubit.load();

      expect(cubit.state.status, OfflinePracticeSessionStatus.error);
      expect(cubit.state.errorMessage, 'offline_package_expired');
      expect(cubit.state.quiz, isNull);

      await cubit.close();
    });
  });

  group('OfflinePrepAccessReconciler', () {
    test('blocks practice when Prep+ access is expired on server', () async {
      const quizId = 'quiz-1';
      final packageRepository = _FakeOfflinePackageRepository(
        _buildQuizPackage(
          quizId: quizId,
          expiresAt: DateTime.utc(2099, 1, 1),
        ),
      );

      final reconciler = OfflinePrepAccessReconciler(
        _FakePrepPlusRepository(
          accesses: PrepMyAccessesModel(
            expired: [
              PrepMyAccessItemModel(
                catalogItemId: 'catalog-1',
                quizId: quizId,
                title: 'Prep quiz',
                questionCount: 10,
                grantedAt: DateTime.utc(2025, 1, 1),
                expiresAt: DateTime.utc(2025, 2, 1),
                canPractice: false,
                canPurchase: true,
              ),
            ],
          ),
        ),
        _FakeConnectivityService(isOnline: true),
        packageRepository,
      );

      final blocked = await reconciler.isOfflinePracticeBlocked(quizId);

      expect(blocked, isTrue);
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

class _FakePrepPlusRepository extends PrepPlusRepository {
  _FakePrepPlusRepository({this.accesses = const PrepMyAccessesModel()})
      : super(ApiClient(baseUrl: 'http://localhost'));

  final PrepMyAccessesModel accesses;

  @override
  Future<PrepMyAccessesModel> getMyAccesses({bool forceRefresh = false}) async =>
      accesses;
}

class _FakeConnectivityService extends NetworkConnectivityService {
  _FakeConnectivityService({required bool isOnline}) : _isOnline = isOnline;

  final bool _isOnline;

  @override
  bool get isOnline => _isOnline;
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

  @override
  Future<void> patchExpiresAt(String quizId, DateTime expiresAt) async {}
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
