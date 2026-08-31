import 'package:web/web.dart' as web;

/// Reads the real browser address bar (path + query), not Flutter's internal route.
Uri getWebBrowserEntryUri() => Uri.parse(web.window.location.href);
