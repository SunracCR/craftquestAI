# CraftQuest 4.0 — Observabilidad con Application Insights

Guía para telemetría del backend (**CraftQuest.Api**): peticiones HTTP, dependencias, consultas SQL y excepciones. Toda la observabilidad del servidor va a **Azure Application Insights** (no Firebase Analytics en el API).

---

## Índice

1. [Qué se recopila automáticamente](#1-qué-se-recopila-automáticamente)
2. [Configuración local (desarrollo)](#2-configuración-local-desarrollo)
3. [Azure App Service](#3-azure-app-service)
4. [Azure Key Vault](#4-azure-key-vault)
5. [Errores HTTP (ProblemDetails)](#5-errores-http-problemdetails)
6. [Usuario autenticado en telemetría](#6-usuario-autenticado-en-telemetría)
7. [Verificación en el portal](#7-verificación-en-el-portal)
8. [Producción: checklist](#8-producción-checklist)

---

## 1. Qué se recopila automáticamente

| Tipo | Origen |
|------|--------|
| Requests HTTP | `Microsoft.ApplicationInsights.AspNetCore` 3.x (OpenTelemetry) |
| Dependencias | Llamadas salientes instrumentadas |
| SQL | `OpenTelemetry.Instrumentation.SqlClient` (EF Core / Azure SQL) |
| Logs | `ILogger<T>` correlacionados con la petición |
| Excepciones | Middleware global + logs explícitos en errores 5xx |

**Paquete:** `Microsoft.ApplicationInsights.AspNetCore` en `CraftQuest.Api`.

**Registro:** `AddCraftQuestApplicationInsights()` en `Program.cs` (extensión en `Extensions/ApplicationInsightsExtensions.cs`).

---

## 2. Configuración local (desarrollo)

Sin connection string, la API arranca con normalidad pero **no envía** telemetría a Azure.

### Opción A — `launchSettings.json` (rápido para pruebas)

En `src/CraftQuest.Api/Properties/launchSettings.json`, perfil `http`:

```json
"environmentVariables": {
  "ASPNETCORE_ENVIRONMENT": "Development",
  "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=...;IngestionEndpoint=..."
}
```

Sustituye el valor por la **Connection string** del recurso Application Insights en Azure Portal → *Overview* → *Connection string*.

> No dejes la variable con valor vacío (`""`): Application Insights 3.x falla al arrancar. Si no usas AI en local, **omite** la variable por completo.
>
> No subas cadenas reales al repositorio. Usa User Secrets o variables de usuario si compartes el repo.

### Opción B — User Secrets (recomendado)

```powershell
cd src\CraftQuest.Api
dotnet user-secrets init
dotnet user-secrets set "ApplicationInsights:ConnectionString" "InstrumentationKey=...;IngestionEndpoint=..."
```

### Opción C — `appsettings.Development.json`

```json
"ApplicationInsights": {
  "ConnectionString": "InstrumentationKey=...;IngestionEndpoint=..."
}
```

Mantén el valor vacío en el archivo versionado y sobrescribe solo en local.

### Prioridad de lectura

1. `APPLICATIONINSIGHTS_CONNECTION_STRING` (variable de entorno)
2. `ApplicationInsights:ConnectionString` (configuración / Key Vault)

---

## 3. Azure App Service

1. Crear recurso **Application Insights** (mismo resource group que la API, si es posible).
2. En el **App Service** → *Configuration* → *Application settings*:
   - Nombre: `APPLICATIONINSIGHTS_CONNECTION_STRING`
   - Valor: connection string del recurso AI
3. Guardar y reiniciar la app.

Alternativa: vincular Application Insights desde *Application Insights* → *Configure* → *Enable* en el App Service (Azure puede inyectar la variable automáticamente).

---

## 4. Azure Key Vault

Si la API ya carga secretos desde Key Vault (misma convención que JWT o media):

| Secreto en Key Vault | Mapeo en la app |
|----------------------|-----------------|
| `ApplicationInsights--ConnectionString` | `ApplicationInsights:ConnectionString` |

O expón el secreto como variable de entorno `APPLICATIONINSIGHTS_CONNECTION_STRING` en el App Service referenciando Key Vault.

---

## 5. Errores HTTP (ProblemDetails)

El middleware `ExceptionHandlingMiddleware` devuelve **RFC 7807** (`application/problem+json`):

| Caso | HTTP | Campo visible al cliente |
|------|------|---------------------------|
| `AppException` | Según excepción | `title` = mensaje de negocio |
| `UnauthorizedAccessException` | 401 | `title` = "Unauthorized." |
| Error inesperado | 500 | `title` genérico; sin `detail` en producción |

Extensiones útiles: `traceId` (correlación con logs y AI).

**Flutter:** los repositorios leen `response.data['title']`; sigue siendo compatible.

En **Development**, errores 500 no controlados pueden incluir `detail` y `stackTrace` en las extensiones.

---

## 6. Usuario autenticado en telemetría

Tras `UseAuthentication`, `UserContextTelemetryMiddleware` etiqueta la actividad OpenTelemetry:

- `enduser.id` — convención estándar (visible en Application Insights)
- `craftquest.userId` — mismo GUID del JWT (`sub` / `NameIdentifier`)

Application Insights **3.x** no usa `ITelemetryInitializer`; el enriquecimiento es vía tags en `Activity.Current`.

---

## 7. Verificación en el portal

1. Ejecutar la API con connection string configurada.
2. Llamar a `GET /health` o cualquier endpoint autenticado.
3. En Azure Portal → Application Insights:
   - **Transaction search** → ver requests y dependencias SQL
   - **Logs** → `traces` / `exceptions` tras provocar un error de prueba
   - **Failures** → excepciones no controladas

Consulta KQL de ejemplo:

```kusto
requests
| where timestamp > ago(1h)
| project timestamp, name, resultCode, duration, user_Id
| order by timestamp desc
```

```kusto
dependencies
| where timestamp > ago(1h)
| where type contains "SQL"
| order by timestamp desc
```

---

## 8. Producción: checklist

- [ ] Recurso Application Insights creado y vinculado al App Service
- [ ] `APPLICATIONINSIGHTS_CONNECTION_STRING` configurada (no en código fuente)
- [ ] `ASPNETCORE_ENVIRONMENT=Production` (sin stack traces en respuestas 500)
- [ ] Alertas opcionales: tasa de errores 5xx, latencia p95, disponibilidad
- [ ] Revisar retención y coste del workspace de Log Analytics asociado

---

## Referencia de código

| Componente | Ruta |
|------------|------|
| Registro DI | `src/CraftQuest.Api/Extensions/ApplicationInsightsExtensions.cs` |
| Excepciones globales | `src/CraftQuest.Api/Middleware/ExceptionHandlingMiddleware.cs` |
| Contexto de usuario | `src/CraftQuest.Api/Middleware/UserContextTelemetryMiddleware.cs` |
| Config base | `src/CraftQuest.Api/appsettings.json` → sección `ApplicationInsights` |
