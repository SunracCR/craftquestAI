import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// App bar expandido + pestañas para pantallas de detalle del módulo Profesor.
///
/// El [title] va en una sola línea con margen para el botón atrás (56px) y las tabs.
class TeacherDetailTabbedAppBar extends StatelessWidget {
  const TeacherDetailTabbedAppBar({
    super.key,
    required this.title,
    required this.bottom,
    this.actions = const [],
    this.expandedHeight = 120,
  });

  final String title;
  final PreferredSizeWidget bottom;
  final List<Widget> actions;
  final double expandedHeight;

  static const double _leadingWidth = 56;
  static const double _tabBarHeight = 48;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      expandedHeight: expandedHeight,
      leadingWidth: _leadingWidth,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        expandedTitleScale: 1.15,
        titlePadding: const EdgeInsetsDirectional.only(
          start: _leadingWidth,
          end: 16,
          bottom: _tabBarHeight + 8,
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      bottom: bottom,
    );
  }
}

/// Aviso bajo el app bar (p. ej. clase archivada). No compite con el título ni el leading.
class TeacherDetailNoticeBanner extends StatelessWidget {
  const TeacherDetailNoticeBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.35),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
