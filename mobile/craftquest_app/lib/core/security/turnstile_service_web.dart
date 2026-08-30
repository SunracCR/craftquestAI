import 'dart:async';
import 'dart:js_interop';

import 'package:craftquest_app/core/security/turnstile_service.dart';
import 'package:web/web.dart' as web;

TurnstileService createTurnstileService() => TurnstileServiceWeb();

@JS('turnstile')
external TurnstileJs get _turnstile;

@JS()
extension type TurnstileJs._(JSObject _) {
  external String render(
    web.HTMLElement container,
    TurnstileRenderOptions options,
  );

  external void execute(String widgetId);

  external void reset(String widgetId);
}

@JS()
extension type TurnstileRenderOptions._(JSObject _) {
  external factory TurnstileRenderOptions({
    String sitekey,
    String size,
    JSFunction callback,
    JSFunction errorCallback,
  });
}

class TurnstileServiceWeb implements TurnstileService {
  TurnstileServiceWeb();

  String? _siteKey;
  String? _widgetId;
  web.HTMLDivElement? _container;
  Completer<String?>? _pending;
  Future<String?>? _inFlight;

  @override
  bool get isConfigured => _siteKey != null && _siteKey!.isNotEmpty;

  @override
  void configure(String? siteKey) {
    final normalized = siteKey?.trim();
    if (normalized == _siteKey) {
      return;
    }

    _completePending(null);
    _pending = null;
    _inFlight = null;

    _siteKey = normalized?.isNotEmpty == true ? normalized : null;
    _widgetId = null;
    _container?.remove();
    _container = null;
  }

  @override
  Future<String?> requestToken({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!isConfigured) {
      return null;
    }

    while (_inFlight != null) {
      await _inFlight;
    }

    final request = _requestTokenInternal(timeout);
    _inFlight = request;
    try {
      return await request;
    } finally {
      if (identical(_inFlight, request)) {
        _inFlight = null;
      }
    }
  }

  Future<String?> _requestTokenInternal(Duration timeout) async {
    await _ensureWidget();
    final widgetId = _widgetId;
    if (widgetId == null || widgetId.isEmpty) {
      return null;
    }

    _completePending(null);
    final completer = Completer<String?>();
    _pending = completer;

    _turnstile.reset(widgetId);
    _turnstile.execute(widgetId);

    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      _completePending(null);
      _turnstile.reset(widgetId);
      return null;
    } finally {
      if (identical(_pending, completer)) {
        _pending = null;
      }
    }
  }

  Future<void> _ensureWidget() async {
    if (_widgetId != null && _widgetId!.isNotEmpty) {
      return;
    }

    _container ??= web.HTMLDivElement()
      ..style.display = 'none'
      ..style.width = '0'
      ..style.height = '0';
    web.document.body?.append(_container!);

    _widgetId = _turnstile.render(
      _container!,
      TurnstileRenderOptions(
        sitekey: _siteKey!,
        size: 'invisible',
        callback: _onToken.toJS,
        errorCallback: _onError.toJS,
      ),
    );
  }

  void _onToken(String token) {
    _completePending(token);
    final widgetId = _widgetId;
    if (widgetId != null && widgetId.isNotEmpty) {
      _turnstile.reset(widgetId);
    }
  }

  void _onError() {
    _completePending(null);
    final widgetId = _widgetId;
    if (widgetId != null && widgetId.isNotEmpty) {
      _turnstile.reset(widgetId);
    }
  }

  void _completePending(String? value) {
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      pending.complete(value);
    }
  }
}
