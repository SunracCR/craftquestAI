import 'package:craftquest_app/features/practice/data/practice_sound_preference_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load returns defaults when key is absent', () async {
    final store = PracticeSoundPreferenceStore();

    final prefs = await store.load();

    expect(prefs.enableSoundEffects, isTrue);
  });

  test('saveSoundEffects persists and load reads back', () async {
    final store = PracticeSoundPreferenceStore();

    await store.saveSoundEffects(false);
    final prefs = await store.load();

    expect(prefs.enableSoundEffects, isFalse);
  });

  test('saveSoundEffects can re-enable sound effects', () async {
    final store = PracticeSoundPreferenceStore();

    await store.saveSoundEffects(false);
    await store.saveSoundEffects(true);
    final prefs = await store.load();

    expect(prefs.enableSoundEffects, isTrue);
  });
}
