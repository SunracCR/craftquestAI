import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Barra inferior de práctica con altura fija: el CTA principal no salta al responder.
class PracticeSessionBottomBar extends StatelessWidget {
  const PracticeSessionBottomBar({
    super.key,
    required this.canGoBack,
    required this.canGoForward,
    required this.allCompleted,
    required this.isBusy,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
    required this.l10n,
  });

  final bool canGoBack;
  final bool canGoForward;
  final bool allCompleted;
  final bool isBusy;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final showFinish = allCompleted;
    final primaryLabel = showFinish
        ? l10n.practiceFinishAction
        : l10n.practiceNextQuestionAction;
    final primaryEnabled = showFinish
        ? !isBusy
        : canGoForward && !isBusy;
    final primaryAction = showFinish ? onFinish : onNext;

    return AppBottomActionBar(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 108,
              child: Opacity(
                opacity: canGoBack ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !canGoBack,
                  child: AppTextActionButton(
                    label: l10n.practicePreviousQuestionAction,
                    onPressed: isBusy ? null : onPrevious,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppGradientPrimaryButton(
                label: primaryLabel,
                icon: showFinish
                    ? Icons.flag_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: primaryEnabled ? primaryAction : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
