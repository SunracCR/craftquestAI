# Variables de entorno — Azure App Service (API CraftQuest)

En **Azure Portal → App Service → Configuration → Application settings**, usa el formato de ASP.NET Core con doble guion bajo `__` (equivale a `:` en JSON).

También puedes usar el slot **Connection strings** para la base de datos (nombre recomendado: `DefaultConnection`, tipo SQLAzure).

---

## Imprescindibles (producción)

| Variable | Ejemplo / notas |
|----------|-----------------|
| `ASPNETCORE_ENVIRONMENT` | `Production` |
| `ConnectionStrings__DefaultConnection` | Cadena SQL Server / Azure SQL (usuario+contraseña o Managed Identity si lo configuráis después) |
| `Jwt__SecretKey` | Clave aleatoria **≥ 32 caracteres** (secreto; rotar periódicamente) |
| `Jwt__Issuer` | `CraftQuest` (o tu dominio) |
| `Jwt__Audience` | `CraftQuest.App` |
| `Cors__AllowedOrigins__0` | Origen Flutter web, p. ej. `https://app.craftquestai.com` |
| `Cors__AllowedOrigins__1` | Otro origen si aplica (admin, etc.) |

Sin `Cors__AllowedOrigins__*` la API **no arranca** en Production.

---

## Application Insights (recomendado)

| Variable | Notas |
|----------|--------|
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Preferido en Azure (auto-inyectado si vinculas App Insights) |
| `ApplicationInsights__ConnectionString` | Alternativa equivalente en código |

---

## Login Google y Apple

| Variable | Obligatorio | Notas |
|----------|-------------|--------|
| `ExternalAuth__Google__WebClientId` | Sí (Google) | Client ID OAuth **Web** (`*.apps.googleusercontent.com`) |
| `ExternalAuth__Google__AdditionalClientIds__0` | No | Client ID Android/iOS extra si el token trae otro `aud` |
| `ExternalAuth__Apple__BundleId` | Sí (Apple iOS) | Debe coincidir con la app: `com.craftquestai.craftquestaiApp` |
| `ExternalAuth__Apple__ServicesId` | Sí (web) | Services ID de Apple Developer |
| `ExternalAuth__Apple__WebRedirectUri` | Sí (web) | Return URL exacta, p. ej. `https://app.craftquestai.com/` |

---

## Pagos — general

| Variable | Producción | Notas |
|----------|------------|--------|
| `Payments__UseMockPayments` | `false` | `true` solo en dev |
| `Payments__CurrencyCode` | `USD` | |
| `Payments__Webhooks__RequireVerification` | `true` | |
| `Payments__Webhooks__GooglePubSubAudience` | `https://<tu-api>/api/webhooks/google-play` | URL pública exacta del push Pub/Sub |

---

## PayPal (web)

| Variable | Notas |
|----------|--------|
| `Payments__PayPal__ClientId` | Sandbox o Live |
| `Payments__PayPal__ClientSecret` | **Secreto** |
| `Payments__PayPal__ApiBaseUrl` | Sandbox: `https://api-m.sandbox.paypal.com` · Live: `https://api-m.paypal.com` |
| `Payments__PayPal__ReturnUrl` | URL de retorno tras aprobar suscripción |
| `Payments__PayPal__CancelUrl` | URL si el usuario cancela |
| `Payments__PayPal__WebhookId` | ID del webhook en PayPal Developer |
| `Payments__PayPal__VerifyWebhooks` | `true` |

### Planes PayPal (IDs `P-...`)

| Variable |
|----------|
| `Payments__PlanProducts__pro__PayPalMonthlyPlanId` |
| `Payments__PlanProducts__pro__PayPalAnnualPlanId` |
| `Payments__PlanProducts__teacher__PayPalMonthlyPlanId` |
| `Payments__PlanProducts__teacher__PayPalAnnualPlanId` |

---

## Google Play (suscripciones Android)

| Variable | Notas |
|----------|--------|
| `Payments__Mobile__GooglePlayPackageName` | p. ej. `com.craftquestai.craftquestai_app` |
| `Payments__Mobile__GooglePlayServiceAccountJsonPath` | **Ruta en el servidor** al JSON de cuenta de servicio (ver abajo) |

**Archivo en App Service:** sube el JSON (Kudu / FTP) a algo como `D:\home\secrets\google-play-service-account.json` y apunta la variable a esa ruta. Hoy el código lee **archivo**, no el contenido en variable.

---

## App Store (suscripciones iOS)

| Variable | Notas |
|----------|--------|
| `Payments__Mobile__AppleBundleId` | p. ej. `com.craftquestai.craftquestaiApp` |
| `Payments__Mobile__AppleIssuerId` | App Store Connect → Keys |
| `Payments__Mobile__AppleKeyId` | ID de la clave API |
| `Payments__Mobile__ApplePrivateKeyPath` | Ruta al `.p8` en el servidor, p. ej. `D:\home\secrets\AuthKey_XXXXX.p8` |
| `Payments__Mobile__AppleEnvironment` | `Sandbox` o `Production` |
| `Payments__Mobile__AppleSharedSecret` | Opcional (legacy `verifyReceipt`) |

Productos (si cambiáis IDs en consolas):

| Variable |
|----------|
| `Payments__PlanProducts__pro__AppStoreProductId` |
| `Payments__PlanProducts__pro__AppStoreAnnualProductId` |
| `Payments__PlanProducts__teacher__AppStoreProductId` |
| `Payments__PlanProducts__teacher__AppStoreAnnualProductId` |
| `Payments__PlanProducts__pro__GooglePlayProductId` |
| `Payments__PlanProducts__pro__GooglePlayAnnualProductId` |
| `Payments__PlanProducts__teacher__GooglePlayProductId` |
| `Payments__PlanProducts__teacher__GooglePlayAnnualProductId` |

---

## IA (Gemini)

| Variable | Notas |
|----------|--------|
| `Ai__Enabled` | `true` / `false` |
| `Ai__UseGemini` | `true` |
| `Ai__GeminiApiKey` | **Secreto** (Google AI Studio) |
| `Ai__GeminiModel` | p. ej. `gemini-2.5-flash` |
| `Ai__GeminiFallbackModels__0` | p. ej. `gemini-2.5-flash-lite` |

El resto de `Ai__*` y `AiGeneration__*` tiene valores por defecto en `appsettings.json`; solo sobrescribid si queréis límites distintos.

---

## Media (producción: Azure Blob)

| Variable | Notas |
|----------|--------|
| `Media__StorageProvider` | `azure` |
| `Media__Azure__ConnectionString` | Cadena de la cuenta de Storage **Secreto** |
| `Media__Azure__ContainerName` | p. ej. `craftquest-media` |
| `Media__PublicBasePath` | `/api/media` (por defecto) |
| `Media__MaxUploadBytes` | Opcional (default 5 MB) |

---

## Restablecer contraseña

| Variable | Notas |
|----------|--------|
| `PasswordReset__Pepper` | **Secreto** dedicado (no reutilizar JWT) |
| `PasswordReset__AppResetUrlBase` | URL de la pantalla Flutter/web, p. ej. `https://app.craftquestai.com/reset-password` |
| `PasswordReset__TokenLifetimeMinutes` | `60` |
| `PasswordReset__FromEmail` | Remitente |
| `PasswordReset__FromDisplayName` | `CraftQuest` |
| `PasswordReset__LogEmailsInDevelopment` | `false` en producción |

> Hoy el envío de correo usa `LoggingEmailSender` (loguea en Application Insights). Para SMTP/Azure Communication Services haría falta otro proveedor.

---

## JWT (opcional, tienen default)

| Variable | Default |
|----------|---------|
| `Jwt__AccessTokenMinutes` | `60` |
| `Jwt__RefreshTokenDays` | `7` |

---

## No van en Azure App Service (app móvil)

Estas se pasan al **compilar/ejecutar Flutter**, no en la API:

| Define | Uso |
|--------|-----|
| `API_BASE_URL` | URL de la API, p. ej. `https://api.craftquestai.com` |
| `GOOGLE_SERVER_CLIENT_ID` | Mismo Web Client ID que `ExternalAuth__Google__WebClientId` |

```bash
flutter build apk --dart-define=API_BASE_URL=https://api.craftquestai.com --dart-define=GOOGLE_SERVER_CLIENT_ID=XXXX.apps.googleusercontent.com
```

---

## Checklist rápido Azure

1. `ASPNETCORE_ENVIRONMENT=Production`
2. Connection string SQL
3. `Jwt__SecretKey` + CORS
4. `ExternalAuth__*` (Google/Apple)
5. `Payments__UseMockPayments=false` + PayPal + webhooks + rutas a secretos Play/Apple
6. `Ai__GeminiApiKey`
7. `Media__StorageProvider=azure` + connection string Blob
8. `PasswordReset__*` + `APPLICATIONINSIGHTS_CONNECTION_STRING`

Marca como **secretos** en Azure (o Key Vault references): `Jwt__SecretKey`, `PasswordReset__Pepper`, `Payments__PayPal__ClientSecret`, `Ai__GeminiApiKey`, `Media__Azure__ConnectionString`, `ConnectionStrings__DefaultConnection`.
