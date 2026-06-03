# Google Play y App Store — suscripciones

## Resumen

| Canal | Verificación en compra | Renovaciones |
|--------|------------------------|--------------|
| **Google Play** | Android Publisher API `subscriptionsv2` | Pub/Sub → `POST /api/webhooks/google-play` |
| **App Store** | App Store Server API (JWT) o `verifyReceipt` legacy | `POST /api/webhooks/app-store` |

La app Flutter envía `verify-purchase` tras `in_app_purchase`; el backend valida con las tiendas y activa/renueva el plan.

## Configuración API (`appsettings`)

```json
"Payments": {
  "UseMockPayments": false,
  "Mobile": {
    "GooglePlayPackageName": "com.craftquestai.craftquestai_app",
    "GooglePlayServiceAccountJsonPath": "secrets/google-play-service-account.json",
    "AppleBundleId": "com.craftquestai.craftquestaiApp",
    "AppleIssuerId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "AppleKeyId": "XXXXXXXXXX",
    "ApplePrivateKeyPath": "secrets/AuthKey_XXXXXXXXXX.p8",
    "AppleEnvironment": "Sandbox",
    "AppleSharedSecret": ""
  },
  "PlanProducts": {
    "pro": {
      "GooglePlayProductId": "craftquest_pro_monthly",
      "GooglePlayAnnualProductId": "craftquest_pro_annual",
      "AppStoreProductId": "craftquest_pro_monthly",
      "AppStoreAnnualProductId": "craftquest_pro_annual"
    },
    "teacher": { ... }
  }
}
```

### Google Play Console

1. Crear productos **Suscripción** (mensual y anual) con los IDs del config.
2. Vincular cuenta de servicio con permiso **Ver datos financieros**.
3. Descargar JSON → `GooglePlayServiceAccountJsonPath`.
4. Real-time developer notifications → tema Pub/Sub → push HTTP a tu API (formato Pub/Sub estándar).

### App Store Connect

1. Crear **Auto-Renewable Subscriptions** (mensual/anual) en el mismo subscription group.
2. App Store Connect → Users and Access → Keys → generar clave API (.p8).
3. Configurar `AppleIssuerId`, `AppleKeyId`, `ApplePrivateKeyPath`.
4. App Store Server Notifications v2 → URL producción/sandbox:  
   `https://<api>/api/webhooks/app-store`

## Endpoints

| Método | Ruta |
|--------|------|
| POST | `/api/billing/mobile/verify-purchase` |
| POST | `/api/webhooks/google-play` |
| POST | `/api/webhooks/app-store` |

Body `verify-purchase`:

```json
{
  "platform": "google_play",
  "productId": "craftquest_pro_monthly",
  "purchaseToken": "<token from Flutter>",
  "transactionId": "<optional, iOS StoreKit 2>"
}
```

## Flutter

- Productos de tienda: tipo **suscripción** en Play Console / App Store Connect.
- `UpgradeablePlanModel` expone IDs mensual y anual; la compra usa el ciclo elegido.
- Tras compra, `verifyMobilePurchase` con `purchaseToken` + `transactionId` (iOS).

## Desarrollo local

`UseMockPayments: true` omite llamadas a Google/Apple y activa el plan con periodo simulado.

## Cancelar renovación

- **PayPal**: `POST /api/billing/cancel` (revoca en PayPal + BD).
- **Google / Apple**: el usuario cancela en la tienda; la app abre Play Store / App Store. Opcionalmente `POST /api/billing/cancel` marca `CancelAtPeriodEnd` en BD si ya canceló en la tienda. Los webhooks sincronizan expiración.

## Seguridad de webhooks (producción)

En `appsettings` con `UseMockPayments: false`:

```json
"Webhooks": {
  "RequireVerification": true,
  "GooglePubSubAudience": "https://<tu-api>/api/webhooks/google-play"
},
"PayPal": {
  "WebhookId": "<id del webhook en PayPal>",
  "VerifyWebhooks": true
}
```

| Proveedor | Verificación |
|-----------|----------------|
| **PayPal** | `POST /v1/notifications/verify-webhook-signature` |
| **Google** | JWT Bearer del push Pub/Sub (`GooglePubSubAudience`) |
| **Apple** | Firma JWS `signedPayload` (cadena x5c de Apple) |

Con `RequireVerification: false` o `UseMockPayments: true` (desarrollo local) no se exige firma.
