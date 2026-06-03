import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/features/billing/presentation/billing_cycle_selector.dart';
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
      'institution' => l10n.billingPlanInstitutionName,
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
  ) =>
      formatPlanPrice(
        context,
        l10n,
        monthlyPrice: monthlyPrice,
        annualPrice: null,
        cycle: BillingCycle.monthly,
      );

  static String formatPlanPrice(
    BuildContext context,
    AppLocalizations l10n, {
    required double? monthlyPrice,
    required double? annualPrice,
    required BillingCycle cycle,
  }) {
    if (monthlyPrice == null && annualPrice == null) {
      return l10n.contactSales;
    }

    final price = cycle == BillingCycle.monthly ? monthlyPrice : annualPrice;
    if (price == null) {
      return l10n.billingAnnualNotAvailable;
    }

    final suffix = cycle == BillingCycle.monthly
        ? l10n.teacherUpgradePriceLabel
        : l10n.billingCycleAnnualPriceSuffix;
    return '${formatMonthlyPrice(context, price)}$suffix';
  }

  static bool isPaidSubscriptionPlan(String? planCode) {
    final code = planCode?.toLowerCase();
    return code == 'pro' || code == 'premium' || code == 'teacher';
  }

  /// Mensaje de plan activo con fecha de renovación o fin de periodo (si aplica).
  static String activePlanBannerMessage(
    BuildContext context,
    AppLocalizations l10n, {
    required String planName,
    required SubscriptionModel subscription,
    String? activeMessage,
  }) {
    final base = activeMessage ?? l10n.subscriptionPlanActive(planName);
    final statusLine = subscriptionStatusLine(
      context,
      l10n,
      subscription: subscription,
    );
    if (statusLine == null) {
      return base;
    }
    return '$base\n$statusLine';
  }

  /// Fecha de renovación o fin de periodo con día de la semana y año.
  static String formatSubscriptionDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('EEE, d MMM y', locale).format(date.toLocal());
  }

  /// Línea de renovación o fin de periodo para suscripciones activas.
  static String? subscriptionStatusLine(
    BuildContext context,
    AppLocalizations l10n, {
    required SubscriptionModel subscription,
  }) {
    if (subscription.cancelAtPeriodEnd || !subscription.autoRenewEnabled) {
      final end = subscription.endsAt ?? subscription.nextBillingAt;
      if (end == null) {
        return null;
      }
      return l10n.teacherUpgradeAccessUntil(
        formatSubscriptionDate(context, end),
      );
    }

    final next = subscription.nextBillingAt ?? subscription.endsAt;
    if (next == null) {
      return null;
    }
    return l10n.teacherUpgradeNextRenewal(
      formatSubscriptionDate(context, next),
    );
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
