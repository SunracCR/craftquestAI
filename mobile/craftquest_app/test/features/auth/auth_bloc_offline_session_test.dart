import 'dart:convert';

import 'package:craftquest_app/core/auth/cached_profile_store.dart';
import 'package:craftquest_app/core/auth/jwt_utils.dart';
import 'package:craftquest_app/core/auth/saved_login_credentials_storage.dart';
import 'package:craftquest_app/core/auth/token_refresh_outcome.dart';
import 'package:craftquest_app/core/auth/token_storage.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:craftquest_app/features/auth/data/models/auth_models.dart';
import 'package:craftquest_app/features/auth/data/session_restore_result.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sampleProfile = UserProfileModel(
  userId: 'user-1',
  email: 'teacher@craftquest.test',
  displayName: 'Teacher',
  roles: ['Teacher'],
);

class TestTokenStorage extends TokenStorage {
  TestTokenStorage() : super();

  String? accessToken;
  String? refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository(super.apiClient, super.cachedProfileStore);

  UserProfileModel? profileResult = _sampleProfile;
  Object? profileError;
  SessionRestoreResult? restoreResult;
  var logoutCalled = false;

  @override
  Future<UserProfileModel> getProfile() async {
    if (profileError != null) {
      throw profileError!;
    }
    return profileResult ?? _sampleProfile;
  }

  @override
  Future<SessionRestoreResult?> restoreProfileAfterSessionFailure(
    DioException error,
  ) async {
    return restoreResult;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

class FakeApiClient extends ApiClient {
  FakeApiClient({required super.tokenStorage});

  TokenRefreshOutcome refreshOutcome = TokenRefreshOutcome.authFailure;

  @override
  Future<TokenRefreshOutcome> refreshTokensDetailed() async => refreshOutcome;
}

String jwtWithExp(DateTime expiryUtc) {
  final expUnix = expiryUtc.millisecondsSinceEpoch ~/ 1000;
  final header = base64Url.encode(utf8.encode('{"alg":"none","typ":"JWT"}'));
  final payload = base64Url.encode(utf8.encode('{"exp":$expUnix}'));
  return '$header.$payload.signature';
}

DioException connectionError() {
  return DioException(
    requestOptions: RequestOptions(path: '/api/auth/me'),
    type: DioExceptionType.connectionError,
  );
}

DioException authError() {
  return DioException(
    requestOptions: RequestOptions(path: '/api/auth/me'),
    response: Response(
      requestOptions: RequestOptions(path: '/api/auth/me'),
      statusCode: 401,
    ),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JwtUtils', () {
    test('isTokenExpired returns false for future exp', () {
      final token = jwtWithExp(
        DateTime.now().toUtc().add(const Duration(days: 1)),
      );
      expect(JwtUtils.isTokenExpired(token), isFalse);
    });

    test('isTokenExpired returns true for past exp', () {
      final token = jwtWithExp(
        DateTime.now().toUtc().subtract(const Duration(days: 1)),
      );
      expect(JwtUtils.isTokenExpired(token), isTrue);
    });
  });

  group('AuthBloc offline session', () {
    late TestTokenStorage tokenStorage;
    late FakeAuthRepository repository;
    late AuthBloc authBloc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await getIt.reset();

      tokenStorage = TestTokenStorage();
      tokenStorage.accessToken = 'access-token';
      tokenStorage.refreshToken = jwtWithExp(
        DateTime.now().toUtc().add(const Duration(days: 3)),
      );

      getIt.registerLazySingleton<TokenStorage>(() => tokenStorage);

      repository = FakeAuthRepository(
        FakeApiClient(tokenStorage: tokenStorage),
        CachedProfileStore.inMemory({}),
      );

      authBloc = AuthBloc(
        repository,
        SavedLoginCredentialsStorage(),
      );
    });

    test('emits authenticated when profile loads online', () async {
      repository.profileError = null;

      authBloc.add(const AuthSessionChecked());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthLoading(),
          isA<AuthAuthenticated>()
              .having((s) => s.user.userId, 'userId', 'user-1')
              .having((s) => s.isOfflineSession, 'isOfflineSession', isFalse),
        ]),
      );
      expect(repository.logoutCalled, isFalse);
    });

    test('emits offline authenticated when restore succeeds after network error',
        () async {
      repository.profileError = connectionError();
      repository.restoreResult = SessionRestoreResult(
        profile: _sampleProfile,
        isOfflineSession: true,
      );

      authBloc.add(const AuthSessionChecked());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthLoading(),
          isA<AuthAuthenticated>()
              .having((s) => s.isOfflineSession, 'isOfflineSession', isTrue),
        ]),
      );
      expect(repository.logoutCalled, isFalse);
    });

    test('logs out when restore fails after auth error', () async {
      repository.profileError = authError();
      repository.restoreResult = null;

      authBloc.add(const AuthSessionChecked());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthUnauthenticated(),
        ]),
      );
      expect(repository.logoutCalled, isTrue);
    });

    test('logs out when restore fails after network error without cache',
        () async {
      repository.profileError = connectionError();
      repository.restoreResult = null;

      authBloc.add(const AuthSessionChecked());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthUnauthenticated(),
        ]),
      );
      expect(repository.logoutCalled, isTrue);
    });

    test('emits unauthenticated when no tokens are stored', () async {
      tokenStorage.accessToken = null;
      tokenStorage.refreshToken = null;

      authBloc.add(const AuthSessionChecked());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthUnauthenticated(),
        ]),
      );
    });
  });

  group('AuthRepository.restoreProfileAfterSessionFailure', () {
    late TestTokenStorage tokenStorage;
    late CachedProfileStore cachedProfileStore;
    late FakeApiClient apiClient;
    late AuthRepository repository;

    setUp(() {
      tokenStorage = TestTokenStorage();
      tokenStorage.refreshToken = jwtWithExp(
        DateTime.now().toUtc().add(const Duration(days: 3)),
      );
      cachedProfileStore = CachedProfileStore.inMemory({});
      apiClient = FakeApiClient(tokenStorage: tokenStorage);
      repository = AuthRepository(apiClient, cachedProfileStore);
    });

    test('returns cached profile on transient failure', () async {
      await cachedProfileStore.save(_sampleProfile);

      final restored = await repository.restoreProfileAfterSessionFailure(
        connectionError(),
      );

      expect(restored, isNotNull);
      expect(restored!.isOfflineSession, isTrue);
      expect(restored.profile.userId, _sampleProfile.userId);
    });

    test('returns null when refresh token is expired', () async {
      tokenStorage.refreshToken = jwtWithExp(
        DateTime.now().toUtc().subtract(const Duration(days: 1)),
      );
      await cachedProfileStore.save(_sampleProfile);

      final restored = await repository.restoreProfileAfterSessionFailure(
        connectionError(),
      );

      expect(restored, isNull);
    });

    test('returns offline profile when auth failure refresh is transient',
        () async {
      await cachedProfileStore.save(_sampleProfile);
      apiClient.refreshOutcome = TokenRefreshOutcome.transientFailure;

      final restored = await repository.restoreProfileAfterSessionFailure(
        authError(),
      );

      expect(restored, isNotNull);
      expect(restored!.isOfflineSession, isTrue);
    });

    test('returns null when auth failure refresh is rejected', () async {
      await cachedProfileStore.save(_sampleProfile);
      apiClient.refreshOutcome = TokenRefreshOutcome.authFailure;

      final restored = await repository.restoreProfileAfterSessionFailure(
        authError(),
      );

      expect(restored, isNull);
    });
  });
}
