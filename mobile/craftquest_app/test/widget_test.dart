import 'package:craftquest_app/app.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(configureDependencies);

  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const CraftQuestApp());
    expect(find.byType(CraftQuestApp), findsOneWidget);
  });
}
