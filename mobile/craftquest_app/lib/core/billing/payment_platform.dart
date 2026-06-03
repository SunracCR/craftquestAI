import 'package:flutter/foundation.dart';

/// Reglas de métodos de pago por plataforma (políticas de tiendas vs web).
abstract final class PaymentPlatform {
  /// Google Play / App Store (app nativa en teléfono o tablet).
  static bool get isMobileStorePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// PayPal solo en web y escritorio; no en apps publicadas en tiendas.
  static bool get supportsPayPalCheckout => !isMobileStorePlatform;
}
