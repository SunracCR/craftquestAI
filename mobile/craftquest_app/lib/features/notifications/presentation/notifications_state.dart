part of 'notifications_cubit.dart';

sealed class NotificationsState {
  const NotificationsState();
}

final class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

final class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded({
    required this.unreadCount,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.listError,
  });

  final int unreadCount;
  final List<NotificationModel> items;
  final String? nextCursor;
  final bool loadingMore;
  final String? listError;

  NotificationsLoaded copyWith({
    int? unreadCount,
    List<NotificationModel>? items,
    String? nextCursor,
    bool? loadingMore,
    String? listError,
    bool clearListError = false,
  }) {
    return NotificationsLoaded(
      unreadCount: unreadCount ?? this.unreadCount,
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      loadingMore: loadingMore ?? this.loadingMore,
      listError: clearListError ? null : (listError ?? this.listError),
    );
  }
}

final class NotificationsError extends NotificationsState {
  const NotificationsError({required this.message});

  final String message;
}
