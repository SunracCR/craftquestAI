# Push notifications (FCM) — CraftQuest

Las notificaciones **in-app** (campana / lista) y las **push del teléfono** son canales independientes:

| Canal | Almacenamiento | Requisito |
|-------|----------------|-----------|
| In-app | `core.Notifications` | Solo API + login |
| Push | FCM + `core.DeviceTokens` | Backend `Push:Enabled` + credenciales Firebase + token del dispositivo |

## Backend (producción)

### Variables Azure App Service

| Variable | Valor |
|----------|--------|
| `Push__Enabled` | `true` |
| `Push__CredentialsPath` | Ruta **absoluta** al JSON de service account |

**Rutas típicas:**

| Entorno | Ejemplo |
|---------|---------|
| Azure App Service **Linux** | `/home/site/secrets/firebase-service-account.json` |
| Azure App Service Windows | `D:\home\secrets\firebase-service-account.json` |
| VM / contenedor Linux | `/var/secrets/firebase-service-account.json` |

En `appsettings.Production.json` dejamos `CredentialsPath` vacío: la ruta real debe venir de **`Push__CredentialsPath`** en variables de entorno (evita rutas Windows en servidores Linux).

Ver también [AZURE_VARIABLES_ENTORNO.md](./AZURE_VARIABLES_ENTORNO.md).

### Subir credenciales Firebase

1. Firebase Console → Project settings → Service accounts → **Generate new private key**.
2. Subir el JSON al App Service (Kudu: `https://<app>.scm.azurewebsites.net` → Debug console → `site/secrets/`).
3. Configurar `Push__CredentialsPath` apuntando al archivo.
4. Reiniciar App Service.

### Logs de diagnóstico (Application Insights)

| Mensaje | Significado |
|---------|-------------|
| `Push (disabled) user=` | `LoggingPushSender` activo — **no se envía FCM** |
| `Firebase push disabled (Push:Enabled or CredentialsPath missing)` | `FirebasePushSender` sin config |
| `FCM skipped for user ...: no device tokens registered` | Backend OK pero **el móvil no registró token** en `core.DeviceTokens` |
| `Firebase credentials file not found at` | Ruta Linux incorrecta o archivo no subido |
| `Firebase Admin SDK initialized for push notifications` | Credenciales OK |
| `FCM sent for user ...: N/M succeeded` | Envío realizado |
| `FCM token rejected` | Token inválido o SHA-1 / app Firebase mal configurada |

### Verificación SQL

Ejecutar [VerifyPushNotifications.sql](./VerifyPushNotifications.sql) tras login en el móvil.

## Cliente Android

### google-services.json

- Ubicación: `mobile/craftquest_app/android/app/google-services.json`
- Gitignored — debe existir **antes** de `flutter build appbundle`
- Package: `com.craftquestai.craftquestai_app`
- Proyecto Firebase esperado: `craftquestai` (verificar `project_id` en el JSON local)

**Verificación local (repo):** el archivo está presente en la máquina de build si compilaste el AAB con FCM; confirma que `package_name` coincide con `applicationId` en `android/app/build.gradle.kts`.

### SHA-1 release en Firebase Console

Desde `mobile/craftquest_app/android/`:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v `
  -keystore craftquestai-release.jks -alias craftquestai
```

Registrar el **SHA-1** en Firebase Console → Project settings → Your apps → Android app.

**Si instalas desde Play Store / prueba interna:** Google **re-firma** la app. Añade también el SHA-1 de **App signing key certificate** (Play Console → Integridad de la app → Certificado de firma de la app), no solo el de tu upload keystore.

### Firebase Cloud Messaging API

Google Cloud Console → proyecto `craftquestai` → APIs & Services → Library → **Firebase Cloud Messaging API** → **Enabled**.

### Test message no llega (checklist)

1. Token **recién generado**: abre la app, login, copia el token de BD (columna `Token` completa, sin truncar).
2. App en **background** (minimizada), no forzada a cerrar en Ajustes.
3. Notificaciones **activadas** para CraftQuestAI (Android 13+).
4. Sin **No molestar** / ahorro de batería agresivo para la app.
5. Mismo proyecto Firebase (`craftquestai`) donde está la app Android `com.craftquestai.craftquestai_app`.
6. Si Play re-firma: SHA-1 de **App signing** en Firebase (ver arriba).

### Permisos en el teléfono (Android 13+)

Ajustes → Apps → CraftQuestAI → Notificaciones → activadas.

## Prueba end-to-end

1. Login en Android release contra `https://api.craftquestai.com`.
2. Confirmar fila `android` en `core.DeviceTokens`.
3. Disparar evento (IA completada, quiz compartido, etc.).
4. **Background:** notificación en bandeja del sistema.
5. **Foreground:** notificación local vía `flutter_local_notifications`.

Prueba manual opcional: Firebase Console → Engage → Messaging → Send test message → pegar token de BD.
