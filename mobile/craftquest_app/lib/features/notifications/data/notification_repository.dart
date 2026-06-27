import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/notifications/data/models/notification_models.dart';
import 'package:dio/dio.dart';

class NotificationRepository {
  NotificationRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<NotificationListResultModel> list({
    String? cursor,
    int limit = 30,
    bool unreadOnly = false,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/notifications',
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
        'unreadOnly': unreadOnly,
      },
    );
    return NotificationListResultModel.fromJson(response.data!);
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/notifications/unread-count',
    );
    return response.data?['count'] as int? ?? 0;
  }

  Future<void> markRead(String notificationId) async {
    await _apiClient.dio.post<void>(
      '/api/notifications/$notificationId/read',
    );
  }

  Future<void> markAllRead() async {
    await _apiClient.dio.post<void>('/api/notifications/read-all');
  }

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    await _apiClient.dio.post<void>(
      '/api/notifications/device-tokens',
      data: {
        'token': token,
        'platform': platform,
      },
    );
  }

  Future<void> removeDeviceToken(String token) async {
    await _apiClient.dio.delete<void>(
      '/api/notifications/device-tokens',
      queryParameters: {'token': token},
    );
  }

  Future<NotificationPreferencesModel> getPreferences() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/notifications/preferences',
    );
    return NotificationPreferencesModel.fromJson(response.data!);
  }

  Future<void> updatePreferences(
    List<NotificationPreferenceModel> preferences,
  ) async {
    await _apiClient.dio.put<void>(
      '/api/notifications/preferences',
      data: {
        'preferences': preferences.map((p) => p.toJson()).toList(),
      },
      options: Options(
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }
}
