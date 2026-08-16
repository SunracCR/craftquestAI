# Secretos del servidor (no commitear)

Coloca aquí en **Azure App Service** (vía Kudu), no en git:

| Archivo | Variable |
|---------|----------|
| `firebase-credentials.json` | `Push__CredentialsPath` |
| `google-play-service-account.json` | `Payments__Mobile__GooglePlayServiceAccountJsonPath` |

Generar Firebase service account: Firebase Console → Project settings → Service accounts → Generate new private key (proyecto **`craftquestai`**; verificar `"project_id"` en el JSON).

**Producción (Linux):** `/home/site/secrets/firebase-credentials.json`  
**Windows (alternativa):** `D:\home\secrets\firebase-credentials.json`

El nombre del archivo puede variar; lo importante es que `Push__CredentialsPath` apunte a la ruta exacta en el App Service.
