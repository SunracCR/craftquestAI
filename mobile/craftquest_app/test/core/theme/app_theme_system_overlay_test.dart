import 'package:craftquest_app/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppBar overlay style does not set deprecated system bar colors', () {
    final style = AppTheme.dark.appBarTheme.systemOverlayStyle;

    expect(style, isNotNull);
    expect(style!.statusBarColor, isNull);
    expect(style.systemNavigationBarColor, isNull);
    expect(style.systemNavigationBarDividerColor, isNull);
    expect(style.statusBarIconBrightness, Brightness.light);
    expect(style.systemNavigationBarIconBrightness, Brightness.light);
  });
}
