import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Mirrors the pending-request completion guard used by [TurnstileServiceWeb].
class TurnstilePendingRequestGuard {
  Completer<String?>? _pending;

  Completer<String?> begin() {
    _complete(null);
    final completer = Completer<String?>();
    _pending = completer;
    return completer;
  }

  void complete(String? value) => _complete(value);

  void _complete(String? value) {
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      pending.complete(value);
    }
  }
}

void main() {
  group('Turnstile pending request guard', () {
    test('ignores late callback after timeout completion', () async {
      final guard = TurnstilePendingRequestGuard();
      final completer = guard.begin();

      guard.complete(null);
      expect(completer.isCompleted, isTrue);

      expect(() => guard.complete('late-token'), returnsNormally);
      expect(await completer.future, isNull);
    });

    test('begin cancels an unfinished request before starting a new one', () async {
      final guard = TurnstilePendingRequestGuard();
      final first = guard.begin();
      final second = guard.begin();

      expect(first.isCompleted, isTrue);
      expect(await first.future, isNull);
      expect(second.isCompleted, isFalse);

      guard.complete('fresh-token');
      expect(await second.future, 'fresh-token');
    });
  });
}
