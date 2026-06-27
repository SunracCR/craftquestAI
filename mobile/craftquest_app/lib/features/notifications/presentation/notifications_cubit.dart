import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/features/notifications/data/models/notification_models.dart';
import 'package:craftquest_app/features/notifications/data/notification_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({required NotificationRepository repository})
      : _repository = repository,
        super(const NotificationsInitial());

  final NotificationRepository _repository;

  int get _preservedUnreadCount => switch (state) {
        NotificationsLoaded(:final unreadCount) => unreadCount,
        NotificationsInitial(:final unreadCount) => unreadCount,
        _ => 0,
      };

  /// Carga lista + contador desde el mismo endpoint (fuente única de verdad).
  Future<void> openInbox() async {
    final current = state;
    if (current is NotificationsLoaded && current.items.isNotEmpty) {
      emit(current.copyWith(isListRefreshing: true, clearListError: true));
    } else {
      emit(
        NotificationsLoaded(
          unreadCount: _preservedUnreadCount,
          isListRefreshing: true,
        ),
      );
    }

    await _fetchInboxPage();
  }

  Future<void> refreshUnreadCount() async {
    try {
      final count = await _repository.getUnreadCount();
      final current = state;
      if (current is NotificationsLoaded) {
        emit(current.copyWith(unreadCount: count));
      } else {
        emit(NotificationsInitial(unreadCount: count));
      }
    } catch (_) {
      // Badge refresh is best-effort (R2).
    }
  }

  Future<void> loadInitial() => openInbox();

  Future<void> refreshList() => openInbox();

  Future<void> _fetchInboxPage() async {
    try {
      var result = await _repository.list();
      if (result.unreadCount > 0 &&
          !result.items.any((n) => !n.isRead)) {
        result = await _repository.list(unreadOnly: true);
      }
      emit(
        NotificationsLoaded(
          unreadCount: result.unreadCount,
          items: result.items,
          nextCursor: result.nextCursor,
        ),
      );
    } on DioException catch (e) {
      _emitInboxError(DioErrorMapper.mapAny(e));
    } catch (e) {
      _emitInboxError(DioErrorMapper.mapAny(e));
    }
  }

  void _emitInboxError(String message) {
    final current = state;
    if (current is NotificationsLoaded && current.items.isNotEmpty) {
      emit(current.copyWith(isListRefreshing: false, listError: message));
    } else {
      emit(NotificationsError(message: message));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! NotificationsLoaded ||
        current.loadingMore ||
        current.isListRefreshing ||
        current.nextCursor == null) {
      return;
    }

    emit(current.copyWith(loadingMore: true));
    try {
      final result = await _repository.list(cursor: current.nextCursor);
      emit(
        current.copyWith(
          items: [...current.items, ...result.items],
          nextCursor: result.nextCursor,
          unreadCount: result.unreadCount,
          loadingMore: false,
          clearListError: true,
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          loadingMore: false,
          listError: DioErrorMapper.mapAny(e),
        ),
      );
    }
  }

  Future<void> markRead(NotificationModel notification) async {
    if (notification.isRead) {
      return;
    }

    final current = state;
    if (current is! NotificationsLoaded) {
      return;
    }

    final updatedItems = current.items
        .map(
          (item) => item.notificationId == notification.notificationId
              ? NotificationModel(
                  notificationId: item.notificationId,
                  type: item.type,
                  title: item.title,
                  body: item.body,
                  isRead: true,
                  createdAt: item.createdAt,
                  readAt: DateTime.now().toUtc(),
                  data: item.data,
                )
              : item,
        )
        .toList();

    final newCount = current.unreadCount > 0 ? current.unreadCount - 1 : 0;
    emit(
      current.copyWith(
        items: updatedItems,
        unreadCount: newCount,
      ),
    );

    try {
      await _repository.markRead(notification.notificationId);
    } catch (_) {
      await refreshUnreadCount();
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllRead();
      await openInbox();
    } catch (_) {
      await refreshUnreadCount();
    }
  }

  void reset() {
    emit(const NotificationsInitial());
  }
}
