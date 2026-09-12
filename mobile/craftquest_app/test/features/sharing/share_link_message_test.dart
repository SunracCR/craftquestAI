import 'package:craftquest_app/features/sharing/presentation/create_share_code_sheet.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('buildShareLinkMessage includes quiz title and join url', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Builder(
          builder: (context) {
            final message = buildShareLinkMessage(
              AppLocalizations.of(context)!,
              title: 'Cuestionario 1',
              joinUrl: 'https://api.craftquestai.com/join/CQ-563141',
              code: 'CQ-563141',
            );
            expect(message, contains('Cuestionario 1'));
            expect(message, contains('https://api.craftquestai.com/join/CQ-563141'));
            expect(message, contains('CQ-563141'));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
