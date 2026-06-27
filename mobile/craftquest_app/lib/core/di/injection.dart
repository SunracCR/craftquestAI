import 'package:craftquest_app/core/compliance/age_signal_service.dart';
import 'package:craftquest_app/core/auth/saved_login_credentials_storage.dart';
import 'package:craftquest_app/core/auth/session_expired_notifier.dart';
import 'package:craftquest_app/core/auth/token_storage.dart';
import 'package:craftquest_app/core/locale/locale_controller.dart';
import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/core/network/network_connectivity_service.dart';
import 'package:craftquest_app/core/services/app_warmup_service.dart';
import 'package:craftquest_app/core/services/deep_link_service.dart';
import 'package:craftquest_app/core/services/sound_service.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/guest/data/guest_repository.dart';
import 'package:craftquest_app/features/guest/data/guest_token_storage.dart';
import 'package:craftquest_app/features/imports/data/import_repository.dart';
import 'package:craftquest_app/features/ai/data/ai_repository.dart';
import 'package:craftquest_app/features/ai_generation/data/study_material_repository.dart';
import 'package:craftquest_app/features/analytics/data/analytics_repository.dart';
import 'package:craftquest_app/features/media/data/media_repository.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/sharing/data/sharing_repository.dart';
import 'package:craftquest_app/features/teacher/data/teacher_assignment_repository.dart';
import 'package:craftquest_app/features/teacher/data/teacher_class_repository.dart';
import 'package:craftquest_app/features/teacher/data/teacher_dashboard_repository.dart';
import 'package:craftquest_app/features/teacher/data/teacher_review_repository.dart';
import 'package:craftquest_app/features/student/data/student_repository.dart';
import 'package:craftquest_app/features/practice/data/practice_preferences_repository.dart';
import 'package:craftquest_app/features/practice/data/practice_repository.dart';
import 'package:craftquest_app/features/practice/data/practice_sound_preference_store.dart';
import 'package:craftquest_app/features/quizzes/data/quiz_repository.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_admin_repository.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:craftquest_app/features/notifications/data/notification_repository.dart';
import 'package:craftquest_app/features/notifications/presentation/notifications_cubit.dart';
import 'package:craftquest_app/core/services/push_notification_service.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  if (getIt.isRegistered<ApiClient>()) {
    return;
  }

  getIt.registerLazySingleton(TokenStorage.new);
  getIt.registerLazySingleton(SavedLoginCredentialsStorage.new);
  getIt.registerLazySingleton(GuestTokenStorage.new);
  getIt.registerLazySingleton(LocaleController.new);
  getIt.registerLazySingleton(AgeSignalService.new);
  getIt.registerLazySingleton(NetworkConnectivityService.new);
  getIt.registerLazySingleton(SessionExpiredNotifier.new);
  getIt.registerLazySingleton(
    () => ApiClient(
      tokenStorage: getIt<TokenStorage>(),
      sessionExpiredNotifier: getIt<SessionExpiredNotifier>(),
    ),
  );
  getIt.registerLazySingleton(() => AuthRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => GuestRepository(getIt<ApiClient>()));
  getIt.registerFactory(
    () => AuthBloc(
      getIt<AuthRepository>(),
      getIt<SavedLoginCredentialsStorage>(),
    ),
  );
  getIt.registerLazySingleton(() => QuizRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => PracticeRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(
    () => PracticePreferencesRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton(PracticeSoundPreferenceStore.new);
  getIt.registerLazySingleton(SoundService.new);
  getIt.registerLazySingleton(DeepLinkService.new);
  getIt.registerLazySingleton(
    () => AppWarmupService(
      getIt<SoundService>(),
      getIt<TeacherDashboardRepository>(),
    ),
  );
  getIt.registerLazySingleton(() => ImportRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => StudentRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => TeacherReviewRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => TeacherClassRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => TeacherAssignmentRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => TeacherDashboardRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => BillingRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => SharingRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => AiRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => StudyMaterialRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => AnalyticsRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => MediaRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => PrepPlusRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(
    () => PrepPlusAdminRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton(
    () => NotificationRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<NotificationsCubit>(
    () => NotificationsCubit(repository: getIt<NotificationRepository>()),
  );
  getIt.registerLazySingleton(
    () => PushNotificationService(getIt<NotificationRepository>()),
  );
}
