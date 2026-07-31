import 'package:craftquest_app/features/ai_generation/presentation/widgets/study_material_upload_zone.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<AppLocalizations> loadL10n() =>
      AppLocalizations.delegate.load(const Locale('es'));

  testWidgets('renders empty zone without DropTarget when file drop unsupported',
      (tester) async {
    final l10n = await loadL10n();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StudyMaterialUploadZone(
            l10n: l10n,
            hasFile: false,
            dragOver: false,
            supportsFileDrop: false,
            uploading: false,
            onPickFile: () {},
            onDragEntered: () {},
            onDragExited: () {},
            onDragDone: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(DropTarget), findsNothing);
    expect(find.text(l10n.excelImportPickFile), findsOneWidget);
  });

  testWidgets('wraps zone with DropTarget when file drop is supported',
      (tester) async {
    final l10n = await loadL10n();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StudyMaterialUploadZone(
            l10n: l10n,
            hasFile: false,
            dragOver: false,
            supportsFileDrop: true,
            uploading: false,
            onPickFile: () {},
            onDragEntered: () {},
            onDragExited: () {},
            onDragDone: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(DropTarget), findsOneWidget);
  });

  testWidgets('shows selected file name when hasFile is true', (tester) async {
    final l10n = await loadL10n();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StudyMaterialUploadZone(
            l10n: l10n,
            hasFile: true,
            dragOver: false,
            supportsFileDrop: true,
            uploading: false,
            fileName: 'material.pdf',
            fileSizeLabel: '120 KB',
            onPickFile: () {},
            onDragEntered: () {},
            onDragExited: () {},
            onDragDone: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('material.pdf'), findsOneWidget);
    expect(find.text('120 KB'), findsOneWidget);
  });
}
