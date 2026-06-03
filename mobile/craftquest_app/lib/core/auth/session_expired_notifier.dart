import 'dart:async';

/// Señal global cuando el refresh token deja de ser válido (emitida una vez por ciclo).
class SessionExpiredNotifier {
  final _controller = StreamController<void>.broadcast();
  bool _pending = false;

  Stream<void> get stream => _controller.stream;

  void notify() {
    if (_pending) {
      return;
    }
    _pending = true;
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  void reset() {
    _pending = false;
  }

  void dispose() {
    _controller.close();
  }
}
