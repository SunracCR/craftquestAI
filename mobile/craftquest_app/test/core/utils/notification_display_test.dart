import 'package:craftquest_app/core/utils/notification_display.dart';
import 'package:craftquest_app/features/notifications/data/models/notification_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationDisplay', () {
    testWidgets('replaces Teacher with Tutor in stored notification body', (
      tester,
    ) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final notification = NotificationModel(
        notificationId: '1',
        type: 'membership_expiring',
        title: 'Membresía por vencer',
        body: 'Tu plan Teacher vence en 7 día(s). Renueva para mantener tus beneficios.',
        isRead: false,
        createdAt: DateTime.utc(2026, 8, 30),
        data: NotificationPayloadModel(planName: 'Teacher', daysRemaining: 7),
      );

      expect(
        NotificationDisplay.localizedBody(l10n, notification),
        contains('Tutor'),
      );
      expect(
        NotificationDisplay.localizedBody(l10n, notification),
        isNot(contains('Teacher')),
      );
    });
  });
}
