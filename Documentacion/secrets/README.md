# Secretos del servidor (no commitear)

Coloca aquí en **Azure App Service** (vía Kudu), no en git:

| Archivo | Variable |
|---------|----------|
| `firebase-service-account.json` | `Push__CredentialsPath` |
| `google-play-service-account.json` | `Payments__Mobile__GooglePlayServiceAccountJsonPath` |

Generar Firebase service account: Firebase Console → Project settings → Service accounts → Generate new private key.

Ruta típica en App Service: `D:\home\secrets\firebase-service-account.json`
