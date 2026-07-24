# Inicio de sesión con Google y Apple

## API

| Método | Ruta | Body |
|--------|------|------|
| POST | `/api/auth/google` | `{ "idToken": "..." }` |
| POST | `/api/auth/apple` | `{ "idToken": "...", "email": "...", "displayName": "..." }` |
| GET | `/api/auth/oauth-config` | Devuelve IDs públicos y flags `isAppleConfigured`, `isAppleWebConfigured` |

`email` y `displayName` en Apple solo en el **primer** inicio (cuando Apple los entrega al cliente).

## Configuración backend (`appsettings`)

Producción ([`appsettings.Production.json`](../src/CraftQuest.Api/appsettings.Production.json)):

```json
"ExternalAuth": {
  "Google": {
    "WebClientId": "<OAuth Web client ID>.apps.googleusercontent.com",
    "AdditionalClientIds": []
  },
  "Apple": {
    "BundleId": "com.craftquestai.craftquestaiApp",
    "ServicesId": "com.craftquestai.web",
    "WebRedirectUri": "https://app.craftquestai.com/"
  }
}
```

| Campo | Uso |
|-------|-----|
| `BundleId` | Audience del identity token en **iOS/macOS** nativo |
| `ServicesId` | Audience del identity token en **web** (y futuro Android vía flujo web) |
| `WebRedirectUri` | Return URL registrada en Apple; debe coincidir **exactamente** (incluye `/` final) |

Variables Azure equivalentes (opcional, sobreescriben JSON):

| Variable | Valor producción |
|----------|------------------|
| `ExternalAuth__Apple__BundleId` | `com.craftquestai.craftquestaiApp` |
| `ExternalAuth__Apple__ServicesId` | `com.craftquestai.web` |
| `ExternalAuth__Apple__WebRedirectUri` | `https://app.craftquestai.com/` |

Tras desplegar la API, verificar:

```http
GET https://api.craftquestai.com/api/auth/oauth-config
```

Respuesta esperada (fragmento):

```json
{
  "isAppleConfigured": true,
  "isAppleWebConfigured": true,
  "appleServicesId": "com.craftquestai.web",
  "appleWebRedirectUri": "https://app.craftquestai.com/"
}
```

### Google Cloud Console

1. Crear proyecto → APIs & Services → Credentials.
2. Crear **OAuth client ID** tipo **Web application** → copiar a `WebClientId`.
3. En ese cliente Web, **Authorized JavaScript origins**:
   - Producción: `https://app.craftquestai.com`
   - Local: `http://localhost:7357` y `http://127.0.0.1:7357` (o el puerto que uses con `flutter run -d chrome --web-port=7357`).
   - Sin el origen de producción, el botón GIS devuelve **400** y en consola: `The given origin is not allowed for the given client ID`.
4. Crear cliente **Android** con package `com.craftquestai.craftquestai_app` + SHA-1 (debug/release).
5. Crear cliente **iOS** con bundle `com.craftquestai.craftquestaiApp` si hace falta; añadir IDs extra a `AdditionalClientIds`.
6. Pantalla de consentimiento OAuth configurada.
7. Habilitar **Google People API** en el mismo proyecto (APIs y servicios → Biblioteca → “People API” → Habilitar). Sin esto, el login en web puede fallar con `403 SERVICE_DISABLED` / `people.googleapis.com`.

### Apple Developer — checklist manual

#### 1. App ID iOS (nativo)

1. [Apple Developer](https://developer.apple.com/account) → **Certificates, Identifiers & Profiles** → **Identifiers**.
2. App ID `com.craftquestai.craftquestaiApp` → habilitar capability **Sign in with Apple**.
3. En **Xcode** (Mac): target `Runner` → **Signing & Capabilities** → añadir **Sign in with Apple** (el entitlement ya está en `ios/Runner/Runner.entitlements`).

#### 2. Services ID (web)

1. Identifiers → **Services IDs** → crear `com.craftquestai.web`.
2. Habilitar **Sign in with Apple** → **Configure**:
   - **Primary App ID:** `com.craftquestai.craftquestaiApp`
   - **Domains and Subdomains:** `app.craftquestai.com`
   - **Return URLs:** registra **ambas** (Apple exige coincidencia exacta con el `redirect_uri`):
     - `https://app.craftquestai.com/`
     - `https://app.craftquestai.com`
3. **Verificar dominio (obligatorio para web):**
   - Apple ofrece descargar `apple-developer-domain-association.txt`.
   - Colócalo en [`mobile/craftquest_app/web/.well-known/apple-developer-domain-association.txt`](../mobile/craftquest_app/web/.well-known/apple-developer-domain-association.txt).
   - Despliega la web. La URL debe devolver el **archivo de texto**, no el HTML de Flutter:
     ```bash
     curl https://app.craftquestai.com/.well-known/apple-developer-domain-association.txt
     ```
   - En Apple Developer, pulsa **Verify** junto a `app.craftquestai.com`.
   - Si esa URL responde con `<!DOCTYPE html>`, el dominio **no** está verificado → error `Invalid web redirect url`.

No hace falta clave `.p8` de Sign in with Apple para login: el backend valida el JWT del cliente contra las claves públicas JWKS de Apple.

### Plataformas soportadas (Apple)

| Plataforma | Botón visible | Mecanismo |
|------------|---------------|-----------|
| iOS | Sí | Nativo (`BundleId` como audience) |
| Web (`app.craftquestai.com`) | Sí | Services ID + redirect web |
| macOS | Sí (UI) | Nativo; falta entitlement en `macos/Runner/*.entitlements` si se publica macOS |
| **Android** | **No** | Sin flujo web implementado; el botón está oculto para evitar errores en runtime |

## Flutter

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<Web client ID>.apps.googleusercontent.com
```

Paquetes: `google_sign_in`, `sign_in_with_apple`. Web: script Apple en `web/index.html`.

Google: `WebClientId` desde API (`GET /api/auth/oauth-config`). Apple web: `ServicesId` + `WebRedirectUri` desde la misma API.

En web, si la API no devuelve `WebRedirectUri`, el cliente usa `'${Uri.base.origin}/'` (p. ej. `https://app.craftquestai.com/` en producción).

### Flutter web (Google)

En web **no** uses `GoogleSignIn.signIn()` para la API: no devuelve `idToken`. La app usa el botón oficial GIS (`renderButton`) + `onCurrentUserChanged`, igual que recomienda `google_sign_in_web`.

## Comportamiento

- Cuenta nueva → usuario + rol student + plan Free + vínculo `google`/`apple` en `core.AuthProviders`.
- Mismo email que registro con contraseña → se **vincula** el proveedor a la cuenta existente.
- Cuenta solo OAuth → `PasswordHash` null (cambio de contraseña no disponible).

## Prueba end-to-end (Apple)

### Pre-requisitos

- [ ] API desplegada con sección `ExternalAuth:Apple` completa
- [ ] App ID iOS con Sign in with Apple + capability en Xcode
- [ ] Services ID `com.craftquestai.web` con dominio y Return URL configurados
- [ ] Web desplegada en `https://app.craftquestai.com`

### iOS (dispositivo físico)

1. Instalar build iOS (TestFlight o Xcode) con bundle `com.craftquestai.craftquestaiApp`.
2. Abrir login → pulsar **Apple**.
3. Completar flujo Apple → debe entrar a la app.

### Web

1. Abrir `https://app.craftquestai.com` → login → **Apple**.
2. Completar flujo (dominio debe estar en Services ID; no funciona en `localhost` sin túnel).

### Verificación SQL

Tras login exitoso, sustituir el GUID del usuario:

```sql
SELECT Provider, ProviderSubject, LinkedAt
FROM core.AuthProviders
WHERE UserId = '00000000-0000-0000-0000-000000000000'
  AND Provider = 'apple';
```

Debe existir una fila con `Provider = 'apple'` y un `ProviderSubject` (sub de Apple).

Errores frecuentes:

| Síntoma | Causa probable |
|---------|----------------|
| `Apple no está configurado en el servidor` | API sin `BundleId` / `ServicesId` |
| `Apple en web requiere Services ID...` | `isAppleWebConfigured: false` en oauth-config |
| `Invalid Apple token` / 401 | Return URL distinta, Services ID incorrecto, o token expirado |
| Botón Apple no visible en Android | Comportamiento esperado (no soportado aún) |
