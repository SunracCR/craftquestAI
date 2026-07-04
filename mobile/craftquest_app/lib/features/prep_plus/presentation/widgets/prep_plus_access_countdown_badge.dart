import 'dart:async';

import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Utilidades y widget de cuenta regresiva para acceso Prep+ (≤5 días restantes).
abstract final class PrepPlusAccessCountdown {
  static const threshold = Duration(days: 5);
  static const _oneHour = Duration(hours: 1);

  static bool shouldShow({
    required bool canPractice,
    required DateTime? accessExpiresAt,
  }) {
    if (!canPractice || accessExpiresAt == null) return false;
    final remaining = _remaining(accessExpiresAt);
    return remaining > Duration.zero && remaining <= threshold;
  }

  static Duration _remaining(DateTime expiresAt) =>
      expiresAt.toUtc().difference(DateTime.now().toUtc());

  static String label(AppLocalizations l10n, DateTime expiresAt) {
    final remaining = _remaining(expiresAt);
    if (remaining <= Duration.zero) {
      return l10n.prepPlusAccessExpired;
    }
    if (remaining <= _oneHour) {
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds % 60;
      final time =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      return l10n.prepPlusAccessCountdownTimer(time);
    }
    if (remaining.inHours >= 24) {
      final days = remaining.inDays;
      return l10n.prepPlusAccessCountdownDays(days);
    }
    return l10n.prepPlusAccessCountdownHours(remaining.inHours);
  }

  static Duration tickInterval(DateTime expiresAt) {
    final remaining = _remaining(expiresAt);
    return remaining <= _oneHour
        ? const Duration(seconds: 1)
        : const Duration(seconds: 60);
  }
}

/// Pill compacta con cuenta regresiva; se actualiza en vivo.
class PrepPlusAccessCountdownBadge extends StatefulWidget {
  const PrepPlusAccessCountdownBadge({
    super.key,
    required this.expiresAt,
    this.onTap,
    this.compact = false,
  });

  final DateTime expiresAt;
  final VoidCallback? onTap;
  final bool compact;

  @override
  State<PrepPlusAccessCountdownBadge> createState() =>
      _PrepPlusAccessCountdownBadgeState();
}

class _PrepPlusAccessCountdownBadgeState
    extends State<PrepPlusAccessCountdownBadge> {
  Timer? _timer;
  late DateTime _expiresAt;

  @override
  void initState() {
    super.initState();
    _expiresAt = widget.expiresAt;
    _scheduleTick();
  }

  @override
  void didUpdateWidget(covariant PrepPlusAccessCountdownBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _expiresAt = widget.expiresAt;
      _scheduleTick();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleTick() {
    _timer?.cancel();
    final remaining = PrepPlusAccessCountdown._remaining(_expiresAt);
    if (remaining <= Duration.zero) return;

    _timer = Timer(PrepPlusAccessCountdown.tickInterval(_expiresAt), () {
      if (!mounted) return;
      setState(() {});
      _scheduleTick();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = PrepPlusAccessCountdown.label(l10n, _expiresAt);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.hourglass_bottom_rounded,
          size: widget.compact ? 14 : 15,
          color: AppColors.warning,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
              fontSize: widget.compact ? 12 : 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? AppSpacing.xs : AppSpacing.sm,
        vertical: widget.compact ? 3 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.45),
        ),
      ),
      child: content,
    );

    if (widget.onTap == null) return pill;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        child: pill,
      ),
    );
  }
}

/// Texto de cuenta regresiva para subtítulos (misma lógica que el badge).
class PrepPlusAccessCountdownText extends StatefulWidget {
  const PrepPlusAccessCountdownText({
    super.key,
    required this.expiresAt,
    this.style,
  });

  final DateTime expiresAt;
  final TextStyle? style;

  @override
  State<PrepPlusAccessCountdownText> createState() =>
      _PrepPlusAccessCountdownTextState();
}

class _PrepPlusAccessCountdownTextState extends State<PrepPlusAccessCountdownText> {
  Timer? _timer;
  late DateTime _expiresAt;

  @override
  void initState() {
    super.initState();
    _expiresAt = widget.expiresAt;
    _scheduleTick();
  }

  @override
  void didUpdateWidget(covariant PrepPlusAccessCountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _expiresAt = widget.expiresAt;
      _scheduleTick();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleTick() {
    _timer?.cancel();
    final remaining = PrepPlusAccessCountdown._remaining(_expiresAt);
    if (remaining <= Duration.zero) return;

    _timer = Timer(PrepPlusAccessCountdown.tickInterval(_expiresAt), () {
      if (!mounted) return;
      setState(() {});
      _scheduleTick();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      PrepPlusAccessCountdown.label(l10n, _expiresAt),
      style: widget.style ??
          const TextStyle(
            color: AppColors.warning,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
