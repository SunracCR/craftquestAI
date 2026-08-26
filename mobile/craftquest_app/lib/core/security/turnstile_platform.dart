import 'package:craftquest_app/core/security/turnstile_service.dart';
import 'package:craftquest_app/core/security/turnstile_service_stub.dart'
    if (dart.library.js_interop) 'package:craftquest_app/core/security/turnstile_service_web.dart';

TurnstileService createPlatformTurnstileService() => createTurnstileService();
