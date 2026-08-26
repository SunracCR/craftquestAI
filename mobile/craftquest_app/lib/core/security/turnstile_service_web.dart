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

  @override
  bool get isConfigured => _siteKey != null && _siteKey!.isNotEmpty;

  @override
  void configure(String? siteKey) {
    final normalized = siteKey?.trim();
    if (normalized == _siteKey) {
      return;
    }

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

    await _ensureWidget();
    if (_widgetId == null || _widgetId!.isEmpty) {
      return null;
    }

    _pending?.complete(null);
    _pending = Completer<String?>();
    _turnstile.execute(_widgetId!);

    try {
      return await _pending!.future.timeout(timeout);
    } on TimeoutException {
      _pending?.complete(null);
      return null;
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
    _pending?.complete(token);
    if (_widgetId != null && _widgetId!.isNotEmpty) {
      _turnstile.reset(_widgetId!);
    }
  }

  void _onError() {
    _pending?.complete(null);
  }
}
