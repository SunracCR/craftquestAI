# Inicio de sesión con Google y Apple

## API

| Método | Ruta | Body |
|--------|------|------|
| POST | `/api/auth/google` | `{ "idToken": "..." }` |
| POST | `/api/auth/apple` | `{ "idToken": "...", "email": "...", "displayName": "..." }` |

`email` y `displayName` en Apple solo en el **primer** inicio (cuando Apple los entrega al cliente).

## Configuración backend (`appsettings`)

```json
"ExternalAuth": {
  "Google": {
    "WebClientId": "<OAuth Web client ID>.apps.googleusercontent.com",
    "AdditionalClientIds": []
  },
  "Apple": {
      "BundleId": "com.craftquestai.craftquestaiApp",
    "ServicesId": ""
  }
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

### Apple Developer (iOS / Android)

1. App ID con capability **Sign in with Apple**.
2. En Xcode (iOS): Signing & Capabilities → Sign in with Apple.
3. `BundleId` debe coincidir con el de la app Flutter iOS.

### Apple en **web** (sí se puede)

Usa un **Services ID**, no el Bundle ID:

1. Identifiers → **Services IDs** → crear (p. ej. `com.craftquestai.web`).
2. Sign in with Apple → **Domains** + **Return URLs** (URL exacta, con `/` final si Apple la pide).
3. API:

```json
"Apple": {
  "BundleId": "com.craftquestai.craftquestaiApp",
  "ServicesId": "com.craftquestai.web",
  "WebRedirectUri": "https://tu-dominio-web/"
}
```

El token web valida con audience = `ServicesId` (ya soportado en el backend).

## Flutter

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<Web client ID>.apps.googleusercontent.com
```

Paquetes: `google_sign_in`, `sign_in_with_apple`. Web: script Apple en `web/index.html`.

Google: `WebClientId` desde API (`GET /api/auth/oauth-config`). Apple web: `ServicesId` + `WebRedirectUri` en la API.

### Flutter web (Google)

En web **no** uses `GoogleSignIn.signIn()` para la API: no devuelve `idToken`. La app usa el botón oficial GIS (`renderButton`) + `signInSilently` / `onCurrentUserChanged`, igual que recomienda `google_sign_in_web`.

## Comportamiento

- Cuenta nueva → usuario + rol student + plan Free + vínculo `google`/`apple` en `core.AuthProviders`.
- Mismo email que registro con contraseña → se **vincula** el proveedor a la cuenta existente.
- Cuenta solo OAuth → `PasswordHash` null (cambio de contraseña no disponible).
