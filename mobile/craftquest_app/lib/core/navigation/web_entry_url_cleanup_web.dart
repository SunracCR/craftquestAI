import 'dart:html' as html;

/// Replaces the browser URL with the app home so consumed entry links are not
/// re-applied after logout.
void clearWebEntryDeepLinkUrl() {
  final origin = html.window.location.origin;
  html.window.history.replaceState(null, '', '$origin/');
}
