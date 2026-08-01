import 'package:craftquest_app/features/auth/data/models/auth_models.dart';

/// Result of attempting to restore a session without a live `/api/auth/me` call.
class SessionRestoreResult {
  const SessionRestoreResult({
    required this.profile,
    required this.isOfflineSession,
  });

  final UserProfileModel profile;
  final bool isOfflineSession;
}
