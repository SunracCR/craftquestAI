import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/features/guest/presentation/bloc/guest_session_cubit.dart';
import 'package:craftquest_app/features/guest/presentation/guest_code_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Acceso destacado al flujo guest («Practicar con código»).
class GuestPracticePromoCard extends StatelessWidget {
  const GuestPracticePromoCard({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final verticalPadding =
        compact ? AppSpacing.sm : AppSpacing.md;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (ctx) => BlocProvider.value(
              value: context.read<GuestSessionCubit>(),
              child: const GuestCodePage(),
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusMd + 4),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusMd + 4),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface.withValues(alpha: 0.98),
                const Color(0xFF2A3840).withValues(alpha: 0.95),
              ],
            ),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.38),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.1),
                blurRadius: 18,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: verticalPadding,
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.accent, AppColors.accentGold],
                    ),
                    boxShadow: compact
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 8 : 10),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.background,
                      size: compact ? 22 : 26,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.guestPracticeWithCodeAction,
                        style: (compact
                                ? Theme.of(context).textTheme.labelLarge
                                : Theme.of(context).textTheme.titleSmall)
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.guestCodeSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.accent.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
