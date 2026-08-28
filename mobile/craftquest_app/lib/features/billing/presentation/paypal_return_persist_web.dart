import 'dart:convert';
import 'dart:html' as html;

const _storageKey = 'cq_pending_paypal_return';

void persistWebPayPalReturnJson(Map<String, dynamic> json) {
  html.window.sessionStorage[_storageKey] = jsonEncode(json);
}

Map<String, dynamic>? readPersistedWebPayPalReturnJson() {
  final raw = html.window.sessionStorage[_storageKey];
  if (raw == null || raw.isEmpty) {
    return null;
  }
  try {
    return jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    html.window.sessionStorage.remove(_storageKey);
    return null;
  }
}

void clearPersistedWebPayPalReturn() {
  html.window.sessionStorage.remove(_storageKey);
}
