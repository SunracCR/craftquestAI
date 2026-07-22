# Checklist E2E — push Android (post-despliegue)

Ejecutar **después** de configurar Azure (`Push__Enabled`, credenciales Firebase) y desplegar API + AAB.

## Pre-requisitos

- [ ] Azure: `Push__Enabled=true`
- [ ] Azure: `Push__CredentialsPath` apunta al JSON válido
- [ ] App Service reiniciado
- [ ] AAB instalado con `google-services.json` presente al compilar
- [ ] SHA-1 release registrado en Firebase Console
- [ ] Notificaciones activadas en Ajustes del teléfono

## Pasos

1. **Login** en Android contra producción.
2. **SQL:** ejecutar [VerifyPushNotifications.sql](./VerifyPushNotifications.sql) — debe aparecer fila `android` con `LastSeenAt` reciente.
3. **Disparar evento:** completar generación IA, compartir quiz, o usar Firebase Console → test message al token de BD.
4. **Background:** minimizar app → debe aparecer notificación en bandeja del sistema.
5. **Foreground:** app abierta → debe aparecer notificación local (mismo título/cuerpo).
6. **Logs API:** no debe aparecer `Push (disabled) user=`; si hay error, buscar `FCM multicast failed`.

## Debug en dispositivo (build debug)

Con `flutter run --release` o debug, filtrar logcat:

```text
[PushNotificationService]
```

Mensajes esperados tras login:

- `Firebase push initialized`
- `Android POST_NOTIFICATIONS granted: true`
- `Device token registered (android)`
