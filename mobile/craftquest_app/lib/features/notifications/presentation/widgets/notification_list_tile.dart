import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/features/notifications/data/models/notification_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationListTile extends StatelessWidget {
  const NotificationListTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final createdLabel = DateFormat.yMMMd(locale).add_Hm().format(
          notification.createdAt.toLocal(),
        );

    return Material(
      color: notification.isRead
          ? Colors.transparent
          : AppColors.accentGold.withValues(alpha: 0.06),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Icon(
          _iconForType(notification.type),
          color: notification.isRead
              ? AppColors.textSecondary
              : AppColors.accentGold,
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight:
                notification.isRead ? FontWeight.w500 : FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              createdLabel,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Tooltip(
                message: l10n.notificationsUnreadBadge,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accentGold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
        onTap: onTap,
      ),
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'quiz_shared' => Icons.menu_book_rounded,
      'class_joined' => Icons.groups_rounded,
      'assignment_created' => Icons.assignment_rounded,
      'assignment_due_soon' => Icons.schedule_rounded,
      'ai_job_completed' => Icons.auto_awesome_rounded,
      'ai_job_failed' => Icons.error_outline_rounded,
      'membership_expiring' => Icons.event_rounded,
      'membership_expired' => Icons.workspace_premium_outlined,
      _ => Icons.notifications_rounded,
    };
  }
}
