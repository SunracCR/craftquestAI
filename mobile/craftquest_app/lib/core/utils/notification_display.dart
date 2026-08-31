import 'package:craftquest_app/core/utils/billing_display.dart';
import 'package:craftquest_app/features/notifications/data/models/notification_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';

/// Texto de notificaciones con nombres de plan localizados (p. ej. Teacher → Tutor).
abstract final class NotificationDisplay {
  static const _membershipTypes = {
    'membership_expiring',
    'membership_expired',
    'payment_issue_pending',
  };

  static String localizedBody(AppLocalizations l10n, NotificationModel notification) {
    final planRef = notification.data?.planName;
    if (planRef == null || planRef.isEmpty) {
      return _replaceLegacyTeacherInBody(l10n, notification.body);
    }

    final localizedPlan = BillingDisplay.localizedPlanName(
      l10n,
      code: planRef,
      name: planRef,
    );

    final body = notification.body.replaceAll(planRef, localizedPlan);
    return _replaceLegacyTeacherInBody(l10n, body);
  }

  static String localizedTitle(AppLocalizations l10n, NotificationModel notification) {
    if (!_membershipTypes.contains(notification.type)) {
      return notification.title;
    }

    final planRef = notification.data?.planName;
    if (planRef == null || planRef.isEmpty) {
      return _replaceLegacyTeacherInBody(l10n, notification.title);
    }

    final localizedPlan = BillingDisplay.localizedPlanName(
      l10n,
      code: planRef,
      name: planRef,
    );

    final title = notification.title.replaceAll(planRef, localizedPlan);
    return _replaceLegacyTeacherInBody(l10n, title);
  }

  static String _replaceLegacyTeacherInBody(AppLocalizations l10n, String text) {
    const legacyTeacher = 'Teacher';
    if (!text.contains(legacyTeacher)) {
      return text;
    }

    final tutor = BillingDisplay.localizedPlanName(l10n, name: legacyTeacher, code: 'teacher');
    return text.replaceAll(legacyTeacher, tutor);
  }
}
