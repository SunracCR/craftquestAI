import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/notifications/presentation/notification_navigation.dart';
import 'package:craftquest_app/features/notifications/presentation/notifications_cubit.dart';
import 'package:craftquest_app/features/notifications/presentation/widgets/notification_list_tile.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Siempre refrescar al abrir: el badge puede tener contador sin lista cargada.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationsCubit>().refreshList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(
        title: l10n.notificationsTitle,
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              final hasUnread = state is NotificationsLoaded &&
                  state.unreadCount > 0;
              if (!hasUnread) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () =>
                    context.read<NotificationsCubit>().markAllRead(),
                child: Text(l10n.notificationsMarkAllRead),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsError) {
            return AppErrorView(
              message: state.message,
              retryLabel: l10n.retry,
              onRetry: () => context.read<NotificationsCubit>().loadInitial(),
            );
          }

          if (state is NotificationsInitial) {
            return const AppLoadingView();
          }

          final loaded = state as NotificationsLoaded;
          if (loaded.items.isEmpty &&
              loaded.unreadCount > 0 &&
              loaded.listError == null) {
            return const AppLoadingView();
          }

          if (loaded.listError != null && loaded.items.isEmpty) {
            return AppErrorView(
              message: loaded.listError!,
              retryLabel: l10n.retry,
              onRetry: () => context.read<NotificationsCubit>().refreshList(),
            );
          }

          if (loaded.items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => context.read<NotificationsCubit>().refreshList(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.4,
                    child: Center(
                      child: Text(
                        l10n.notificationsEmpty,
                        style: const TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<NotificationsCubit>().refreshList(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.extentAfter < 120 &&
                    loaded.nextCursor != null &&
                    !loaded.loadingMore) {
                  context.read<NotificationsCubit>().loadMore();
                }
                return false;
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: loaded.items.length + (loaded.loadingMore ? 1 : 0),
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppColors.textSecondary.withValues(alpha: 0.12),
                ),
                itemBuilder: (context, index) {
                  if (index >= loaded.items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final item = loaded.items[index];
                  return NotificationListTile(
                    notification: item,
                    onTap: () async {
                      final cubit = context.read<NotificationsCubit>();
                      await cubit.markRead(item);
                      if (!context.mounted) return;
                      await NotificationNavigation.open(context, item);
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Campana con badge de no leídas para el AppBar del Home.
class NotificationBellAction extends StatelessWidget {
  const NotificationBellAction({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final unreadCount = switch (state) {
          NotificationsLoaded(:final unreadCount) => unreadCount,
          NotificationsInitial(:final unreadCount) => unreadCount,
          _ => 0,
        };

        return IconButton(
          tooltip: l10n.notificationsTitle,
          onPressed: () {
            unawaited(getIt<NotificationsCubit>().refreshList());
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider.value(
                  value: getIt<NotificationsCubit>(),
                  child: const NotificationsPage(),
                ),
              ),
            );
          },
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}
