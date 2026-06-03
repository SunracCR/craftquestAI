import 'dart:async';

import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/auth/presentation/register_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Anuncio de beneficios al registrarse; se cierra solo tras [autoCloseDuration].
class GuestRegisterBenefitsPromoPage extends StatefulWidget {
  const GuestRegisterBenefitsPromoPage({
    super.key,
    this.autoCloseDuration = const Duration(seconds: 10),
  });

  static const Duration defaultAutoCloseDuration = Duration(seconds: 10);

  final Duration autoCloseDuration;

  @override
  State<GuestRegisterBenefitsPromoPage> createState() =>
      _GuestRegisterBenefitsPromoPageState();
}

class _GuestRegisterBenefitsPromoPageState
    extends State<GuestRegisterBenefitsPromoPage> {
  static const _ctaGradient = LinearGradient(
    colors: [AppColors.accent, AppColors.accentGold],
  );

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.autoCloseDuration.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer timer) {
    if (!mounted) return;
    if (_secondsRemaining <= 1) {
      timer.cancel();
      _close();
      return;
    }
    setState(() => _secondsRemaining--);
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop();
  }

  void _goRegister() {
    _timer?.cancel();
    final authBloc = context.read<AuthBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: authBloc,
          child: const RegisterPage(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final totalSeconds = widget.autoCloseDuration.inSeconds;
    final progress = totalSeconds > 0
        ? (_secondsRemaining / totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: l10n.guestRegisterPromoSkipTooltip,
                  onPressed: _close,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 48,
                        color: AppColors.accentGold.withValues(alpha: 0.95),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.guestRegisterCtaTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.guestRegisterPromoSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _BenefitsCard(l10n: l10n),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: AppColors.surface,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.guestRegisterPromoCountdown(_secondsRemaining),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppGradientPrimaryButton(
                label: l10n.guestRegisterAction,
                icon: Icons.person_add_alt_1_rounded,
                onPressed: _goRegister,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _close,
                child: Text(l10n.guestViewResultsAction),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.14),
            AppColors.accentGold.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.guestRegisterPromoBenefitsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient:
                      _GuestRegisterBenefitsPromoPageState._ctaGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.guestShellFreeBadge.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.background,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _BenefitRow(text: l10n.guestRegisterBenefit1),
          _BenefitRow(text: l10n.guestRegisterBenefit2),
          _BenefitRow(text: l10n.guestRegisterBenefit3),
          _BenefitRow(text: l10n.guestRegisterBenefit4),
          _BenefitRow(text: l10n.guestRegisterBenefit5),
          _BenefitRow(text: l10n.guestRegisterBenefit6),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.accentMint.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: AppColors.accentMint,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
