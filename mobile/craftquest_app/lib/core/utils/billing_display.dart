import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Etiquetas y precios de planes localizados para billing y perfil docente.
abstract final class BillingDisplay {
  static String localizedPlanName(
    AppLocalizations l10n, {
    String? code,
    String? name,
  }) {
    final normalized = (code ?? name ?? 'free').trim().toLowerCase();
    return switch (normalized) {
      'free' => l10n.billingPlanFreeName,
      'pro' => l10n.billingPlanProName,
      'premium' => l10n.billingPlanPremiumName,
      'teacher' => l10n.billingPlanTeacherName,
      _ => name?.trim().isNotEmpty == true
          ? name!.trim()
          : code ?? l10n.billingPlanFreeName,
    };
  }

  static String formatMonthlyPrice(BuildContext context, double? monthlyPrice) {
    final l10n = AppLocalizations.of(context)!;
    if (monthlyPrice == null) {
      return l10n.contactSales;
    }
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.simpleCurrency(locale: locale, name: 'USD')
        .format(monthlyPrice);
  }

  static String formatMonthlyPriceWithPeriod(
    BuildContext context,
    AppLocalizations l10n,
    double? monthlyPrice,
  ) {
    if (monthlyPrice == null) {
      return l10n.contactSales;
    }
    return '${formatMonthlyPrice(context, monthlyPrice)}${l10n.teacherUpgradePriceLabel}';
  }

  static String formatQuizzesUsage(
    AppLocalizations l10n, {
    required int quizzesCreated,
    int? maxQuizzes,
  }) {
    if (maxQuizzes == null) {
      return l10n.billingQuizzesUnlimited;
    }
    return l10n.billingUsageLabel(quizzesCreated, maxQuizzes.toString());
  }
}
