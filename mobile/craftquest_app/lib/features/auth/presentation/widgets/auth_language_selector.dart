import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/locale/locale_controller.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/features/profile/presentation/widgets/profile_language_selector.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Selector compacto de idioma (pill) para pantallas de autenticación.
class AuthLanguageSelector extends StatelessWidget {
  const AuthLanguageSelector({super.key});

  static const _languageCodes = ['es', 'en', 'pt'];

  String _label(AppLocalizations l10n, String code) => switch (code) {
        'es' => l10n.languageSpanish,
        'en' => l10n.languageEnglish,
        'pt' => l10n.languagePortuguese,
        _ => code,
      };

  @override
  Widget build(BuildContext context) {
    final localeController = getIt<LocaleController>();
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final currentCode = localeController.locale?.languageCode ??
            Localizations.localeOf(context).languageCode;
        final resolvedCode =
            _languageCodes.contains(currentCode) ? currentCode : 'es';

        return PopupMenuButton<String>(
          tooltip: l10n.languageSectionTitle,
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
          ),
          color: AppColors.surface,
          onSelected: (code) {
            if (code == resolvedCode) return;
            localeController.setLocale(Locale(code), persist: true);
          },
          itemBuilder: (context) => [
            for (final code in _languageCodes)
              PopupMenuItem<String>(
                value: code,
                child: Row(
                  children: [
                    Text(
                      ProfileLanguageSelector.flagFor(code),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _label(l10n, code),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: code == resolvedCode
                                  ? AppColors.accentMint
                                  : AppColors.textPrimary,
                              fontWeight: code == resolvedCode
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                      ),
                    ),
                    if (code == resolvedCode)
                      const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: AppColors.accentMint,
                      ),
                  ],
                ),
              ),
          ],
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ProfileLanguageSelector.flagFor(resolvedCode),
                    style: const TextStyle(fontSize: 16, height: 1),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    resolvedCode.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
