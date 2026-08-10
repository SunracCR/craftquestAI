import 'package:craftquest_app/core/widgets/app_answer_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppAnswerTile shows radio icons in single mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppAnswerTile(
            label: 'Option A',
            selected: false,
            selectionMode: AnswerSelectionMode.single,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsNothing);
  });

  testWidgets('AppAnswerTile shows checkbox icons in multiple mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppAnswerTile(
            label: 'Option A',
            selected: true,
            selectionMode: AnswerSelectionMode.multiple,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_box), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked), findsNothing);
  });
}
