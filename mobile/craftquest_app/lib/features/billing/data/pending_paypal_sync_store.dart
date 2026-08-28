import 'pending_paypal_sync_store_stub.dart'
    if (dart.library.html) 'pending_paypal_sync_store_web.dart' as impl;

void writePendingPayPalSyncJson(Map<String, dynamic> json) =>
    impl.writePendingPayPalSyncJson(json);

Map<String, dynamic>? readPendingPayPalSyncJson() =>
    impl.readPendingPayPalSyncJson();

void clearPendingPayPalSync() => impl.clearPendingPayPalSync();
