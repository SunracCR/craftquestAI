import 'package:craftquest_app/core/config/legal_urls.dart';
import 'package:craftquest_app/core/l10n/localized_message_holder.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre una URL legal en el navegador externo.
Future<void> openLegalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) {
    _showOpenUrlError();
    return;
  }

  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      _showOpenUrlError();
    }
  } catch (_) {
    _showOpenUrlError();
  }
}

void _showOpenUrlError() {
  final message = LocalizedMessageHolder.current?.genericRequestErrorMessage ??
      'No se pudo abrir el enlace. Inténtalo de nuevo.';
  AppSnackBars.showError(message);
}

/// Texto con enlaces a Términos y Política de Privacidad (registro).
class RegisterLegalDisclaimer extends StatelessWidget {
  const RegisterLegalDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          height: 1.4,
        );
    final linkStyle = style?.copyWith(
      color: AppColors.accent,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            TextSpan(text: l10n.registerLegalDisclaimerPrefix),
            TextSpan(
              text: l10n.termsOfServiceLink,
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => openLegalUrl(LegalUrls.termsOfServiceUrl),
            ),
            TextSpan(text: l10n.registerLegalDisclaimerAnd),
            TextSpan(
              text: l10n.privacyPolicyLink,
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => openLegalUrl(LegalUrls.privacyPolicyUrl),
            ),
            TextSpan(text: l10n.registerLegalDisclaimerSuffix),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Enlaces compactos para login y perfil.
class LegalLinksRow extends StatelessWidget {
  const LegalLinksRow({super.key, this.centered = true});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final linkStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
        );

    final row = Wrap(
      alignment: centered ? WrapAlignment.center : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => openLegalUrl(LegalUrls.privacyPolicyUrl),
          child: Text(l10n.privacyPolicyLink, style: linkStyle),
        ),
        Text('·', style: linkStyle?.copyWith(color: AppColors.textSecondary)),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => openLegalUrl(LegalUrls.termsOfServiceUrl),
          child: Text(l10n.termsOfServiceLink, style: linkStyle),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: centered ? Center(child: row) : row,
    );
  }
}
