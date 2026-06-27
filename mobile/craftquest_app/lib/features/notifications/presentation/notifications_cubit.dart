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

  Future<void> refreshUnreadCount() async {
    try {
      final count = await _repository.getUnreadCount();
      final current = state;
      if (current is NotificationsLoaded) {
        emit(current.copyWith(unreadCount: count));
      } else if (current is NotificationsInitial) {
        emit(NotificationsInitial(unreadCount: count));
      } else {
        emit(NotificationsInitial(unreadCount: count));
      }
    } catch (_) {
      // Badge refresh is best-effort (R2).
    }
  }

  Future<void> loadInitial() async {
    try {
      final result = await _repository.list();
      emit(
        NotificationsLoaded(
          unreadCount: result.unreadCount,
          items: result.items,
          nextCursor: result.nextCursor,
        ),
      );
    } on DioException catch (e) {
      emit(NotificationsError(message: DioErrorMapper.mapAny(e)));
    } catch (e) {
      emit(NotificationsError(message: DioErrorMapper.mapAny(e)));
    }
  }

  Future<void> refreshList() async {
    try {
      final result = await _repository.list();
      emit(
        NotificationsLoaded(
          unreadCount: result.unreadCount,
          items: result.items,
          nextCursor: result.nextCursor,
        ),
      );
    } on DioException catch (e) {
      final current = state;
      if (current is NotificationsLoaded) {
        emit(current.copyWith(listError: DioErrorMapper.mapAny(e)));
      } else {
        emit(NotificationsError(message: DioErrorMapper.mapAny(e)));
      }
    } catch (e) {
      final current = state;
      if (current is NotificationsLoaded) {
        emit(current.copyWith(listError: DioErrorMapper.mapAny(e)));
      } else {
        emit(NotificationsError(message: DioErrorMapper.mapAny(e)));
      }
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! NotificationsLoaded ||
        current.loadingMore ||
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
      await refreshList();
    } catch (_) {
      await refreshUnreadCount();
    }
  }

  void reset() {
    emit(const NotificationsInitial());
  }
}
