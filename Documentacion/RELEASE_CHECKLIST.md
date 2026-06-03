# Checklist de release — CraftQuest

Usar antes de desplegar a **staging** o **producción**. Complementa `SQL_Migration_Checklist.md` y `CraftQuest_Configuracion_Media_Pagos_v4.md`.

## Seguridad y configuración

- [ ] **JWT**: `Jwt:SecretKey` fuerte (≥ 32 caracteres aleatorios) solo en variables de entorno / Key Vault — **nunca** el valor de desarrollo de `appsettings.json`
- [ ] `appsettings.*.local.json` y secretos **no** commiteados (ya en `.gitignore`)
- [ ] HTTPS obligatorio en API y URLs de retorno PayPal
- [ ] CORS restringido a dominios de la app (no `AllowAnyOrigin` en prod si se añade)
- [ ] Revisar que `UseMockPayments` sea **`false`** en producción

## Base de datos

- [ ] Todos los scripts aplicados según `SQL_Migration_Checklist.md` (marcar Dev/Staging/Prod)
- [ ] Backup antes de cambios DDL en producción

## Media

- [ ] Storage **Azure Blob** si hay varias instancias de API (disco local no compartido)
- [ ] Contenedor privado; lectura vía `GET /api/media/{id}/file` con JWT o cabeceras invitado
- [ ] `Media:PublicBasePath` y `MaxUploadBytes` revisados

## Pagos

- [ ] PayPal Live: credenciales, `api-m.paypal.com`, Return/Cancel URLs públicas HTTPS
- [ ] Productos IAP publicados; IDs alineados con `PlanProducts`
- [ ] Verificación servidor Google Play / App Store implementada (no solo mock)
- [ ] Webhooks PayPal (opcional, renovaciones)

## Recuperación de contraseña

- [ ] Script `PasswordReset_Feature.sql` aplicado
- [ ] `PasswordReset:Pepper` único por entorno (variable de entorno, no el valor de dev)
- [ ] `PasswordReset:AppResetUrlBase` apunta a la URL Flutter web (ruta `/reset-password`)
- [ ] Proveedor de correo real configurado (hoy los emails se registran en log vía `LoggingEmailSender`)

## API

- [ ] Endpoint anónimo `questions/student-view` **eliminado** (contenido solo vía práctica autenticada)
- [ ] Documentación de rutas billing: `Billing_API_Routes.md`

## Flutter / clientes

- [ ] `API_BASE_URL` apunta al host de producción
- [ ] Build release (no `--dart-define` de dev salvo entornos de prueba)
- [ ] “Recordar correo” activo; contraseña **no** se guarda en dispositivo

## Operación

- [ ] Health `/health` y logs monitorizados
- [ ] Rotación / retención de `logs/ai-gen-trace/` en servidor
