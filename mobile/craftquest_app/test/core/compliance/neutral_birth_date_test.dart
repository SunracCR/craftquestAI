import 'package:craftquest_app/core/compliance/age_collection_storage.dart';
import 'package:craftquest_app/core/compliance/age_screen.dart';
import 'package:craftquest_app/core/compliance/compliance_pref_cache.dart';
import 'package:craftquest_app/core/compliance/neutral_birth_date.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final today = DateTime(2026, 10, 9);

  group('NeutralBirthDate.parse', () {
    test('returns null until day, month and year are complete', () {
      expect(
        NeutralBirthDate.parse(
          dayText: '1',
          yearText: '201',
          month: 1,
          today: today,
        ),
        isNull,
      );
    });

    test('rejects a future date and an impossible day', () {
      expect(
        NeutralBirthDate.parse(
          dayText: '10',
          yearText: '2026',
          month: 10,
          today: today,
        ),
        isNull,
      );
      expect(
        NeutralBirthDate.parse(
          dayText: '31',
          yearText: '2015',
          month: 2,
          today: today,
        ),
        isNull,
      );
    });

    test('accepts a real date within the last 100 years', () {
      expect(
        NeutralBirthDate.parse(
          dayText: '1',
          yearText: '2016',
          month: 1,
          today: today,
        ),
        DateTime(2016, 1, 1),
      );
    });
  });

  group('AgeScreen', () {
    late AgeCollectionStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await getIt.reset();
      final cache = CompliancePrefCache();
      await cache.warmUp();
      storage = AgeCollectionStorage(cache);
      getIt.registerSingleton<CompliancePrefCache>(cache);
      getIt.registerSingleton<AgeCollectionStorage>(storage);
    });

    tearDown(() async {
      await getIt.reset();
    });

    testWidgets('starts empty and stores a minor date without an age prompt', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AgeScreen(onCompleted: () => completed = true),
        ),
      );
      await tester.pump();

      final dayField = tester.widget<TextField>(find.byType(TextField).at(0));
      final yearField = tester.widget<TextField>(find.byType(TextField).at(1));
      final monthField = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>),
      );
      expect(dayField.controller?.text ?? '', isEmpty);
      expect(yearField.controller?.text ?? '', isEmpty);
      expect(monthField.value, isNull);

      final continueInk = find.ancestor(
        of: find.text('Continuar'),
        matching: find.byType(InkWell),
      );
      expect(tester.widget<InkWell>(continueInk).onTap, isNull);
      expect(find.textContaining('menor de edad'), findsNothing);
      expect(find.textContaining('debes tener'), findsNothing);
      expect(find.textContaining('must be'), findsNothing);

      final year = DateTime.now().year - 10;
      await tester.enterText(find.byType(TextField).at(0), '1');
      await tester.enterText(find.byType(TextField).at(1), '$year');
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();

      final monthName = DateFormat.MMMM('es').format(DateTime(2000, 1));
      await tester.tap(find.text(monthName).last);
      await tester.pumpAndSettle();

      expect(tester.widget<InkWell>(continueInk).onTap, isNotNull);
      await tester.tap(continueInk);
      await tester.pump();
      await tester.pump();

      expect(completed, isTrue);
      expect(await storage.isMinor(), isTrue);
      expect(getIt<CompliancePrefCache>().isMinor, isTrue);
      expect(find.textContaining('menor de edad'), findsNothing);
    });
  });
}
