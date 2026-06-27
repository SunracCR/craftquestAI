import 'web_entry_url_cleanup_stub.dart'
    if (dart.library.html) 'web_entry_url_cleanup_web.dart' as impl;

void clearWebEntryDeepLinkUrl() => impl.clearWebEntryDeepLinkUrl();
