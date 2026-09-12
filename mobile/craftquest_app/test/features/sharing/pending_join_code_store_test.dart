import 'package:craftquest_app/features/sharing/data/pending_join_code_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save and read pending join code', () async {
    final store = PendingJoinCodeStore(SharedPreferences.getInstance());
    await store.save('cq-563141');
    expect(await store.read(), 'CQ-563141');
  });

  test('clear removes pending join code', () async {
    final store = PendingJoinCodeStore(SharedPreferences.getInstance());
    await store.save('CQ-563141');
    await store.clear();
    expect(await store.read(), isNull);
  });
}
