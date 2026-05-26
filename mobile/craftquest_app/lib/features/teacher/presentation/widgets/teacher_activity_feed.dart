import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/widgets/member_avatar.dart';
import 'package:flutter/material.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_dashboard_models.dart';

class TeacherActivityFeed extends StatelessWidget {
  const TeacherActivityFeed({super.key, required this.items, this.onTap});

  final List<ActivityFeedItemModel> items;
  final void Function(ActivityFeedItemModel)? onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        color: AppColors.surfaceHighlight,
      ),
      itemBuilder: (_, i) => _ActivityFeedTile(item: items[i], onTap: onTap),
    );
  }
}

class _ActivityFeedTile extends StatelessWidget {
  const _ActivityFeedTile({required this.item, this.onTap});

  final ActivityFeedItemModel item;
  final void Function(ActivityFeedItemModel)? onTap;

  @override
  Widget build(BuildContext context) {
    final scoreColor = item.passed ? AppColors.accentMint : AppColors.error;

    return ListTile(
      onTap: onTap != null ? () => onTap!(item) : null,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: MemberAvatar(
        avatarId: item.studentAvatarId,
        displayName: item.studentName,
        size: 40,
      ),
      title: Text(
        item.studentName,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        item.assignmentTitle != null
            ? '${item.assignmentTitle} · ${item.quizTitle}'
            : item.quizTitle,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${item.scorePercent}%',
            style: TextStyle(
              color: scoreColor,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          Text(
            _timeAgo(item.completedAt),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
