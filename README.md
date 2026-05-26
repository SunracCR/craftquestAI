# CraftQuest

Plataforma educativa de cuestionarios y practica (MVP v4).

## Requisitos

- .NET 10 SDK
- SQL Server local (`EE0628-GA\EE0628`)
- Flutter 3.27+

## Base de datos

```powershell
sqlcmd -S "EE0628-GA\EE0628" -C -E -Q "IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = N'CraftQuest') CREATE DATABASE CraftQuest;"
sqlcmd -S "EE0628-GA\EE0628" -C -E -d CraftQuest -i Documentacion\CraftQuest_AzureSQL_DDL_MVP_Completo_v4.sql
```

## API

Confía el certificado de desarrollo HTTPS (una vez por máquina):

```powershell
dotnet dev-certs https --trust
```

```powershell
cd src\CraftQuest.Api
dotnet run --launch-profile https
```

- Swagger: https://localhost:7080/swagger
- Health: https://localhost:7080/health
- Status: https://localhost:7080/api/status
- HTTP legado (redirige a HTTPS): http://localhost:5080
- Auth: `POST /api/auth/register`, `POST /api/auth/login`, `POST /api/auth/refresh`, `GET /api/auth/me`
- Quizzes: `GET /api/question-types`, `POST/GET/PATCH /api/quizzes`, `POST/GET /api/quizzes/{id}/questions`
- Vista estudiante (sin correctas): `GET /api/quizzes/{id}/questions/student-view`
- Media: `POST /api/media/upload`, `GET /api/media/{id}/file`
- Billing / pagos: `GET /api/billing/me`, `GET /api/billing/plans`, PayPal e IAP (ver guía anterior)

## Flutter

```powershell
cd mobile\craftquest_app
flutter pub get
flutter run
```

En emulador Android use HTTPS al host:

```powershell
flutter run --dart-define=API_BASE_URL=https://10.0.2.2:7080
```

(Solo HTTP local: perfil `http` y `API_BASE_URL=http://10.0.2.2:5080`.)

### Android 15 edge-to-edge

- `targetSdk` / `compileSdk` 35
- `MainActivity` llama `enableEdgeToEdge()`
- Pantallas usan `EdgeAwareScaffold` con `SafeArea`

Ver `mobile/craftquest_app/README.md`.

## Dominios (CraftQuestAI.com)

Hoy todo corre en **local**. Cuando despliegues, la convención prevista es:

| Rol | URL |
|-----|-----|
| API | `https://api.craftquestai.com` |
| App web (Flutter) | `https://app.craftquestai.com` |
| Sitio / marketing | `https://craftquestai.com` |

- Contrato OpenAPI: `Documentacion/CraftQuest_OpenAPI_MVP_v4.yaml`
- Config de producción de ejemplo: `src/CraftQuest.Api/appsettings.Production.json.example` (copiar a `appsettings.Production.json` o usar variables de entorno)
- Flutter producción: `flutter build web --dart-define=API_BASE_URL=https://api.craftquestai.com`

En **Development** la API acepta cualquier origen CORS (localhost, emulador, etc.). En **Production** exige `Cors:AllowedOrigins` configurado.

## Estructura

- `src/` - Backend .NET (Clean Architecture)
- `mobile/craftquest_app/` - App Flutter
- `Documentacion/` - Contratos v4 (OpenAPI, DDL, CQIF)

## Media, imágenes y pagos

Guía de configuración (Azure Blob, subida Flutter, PayPal, IAP, modo mock):

- [Documentacion/CraftQuest_Configuracion_Media_Pagos_v4.md](Documentacion/CraftQuest_Configuracion_Media_Pagos_v4.md)