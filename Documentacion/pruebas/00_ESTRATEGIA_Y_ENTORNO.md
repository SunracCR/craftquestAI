# 00 — Estrategia y entorno de pruebas — CraftQuest

Este documento define la estrategia global, prioridades, entornos y plantillas para ejecutar el plan de pruebas integral de CraftQuest (backend .NET + app Flutter).

## Índice de documentos

| # | Archivo | Ámbito |
|---|---------|--------|
| 00 | `00_ESTRATEGIA_Y_ENTORNO.md` | Este documento |
| 01 | `01_BACKEND_AUTH.md` | Auth, OAuth, AccountLinks |
| 02 | `02_BACKEND_QUIZZES_PRACTICE.md` | Quizzes, Practice, Guest, Imports |
| 03 | `03_BACKEND_AI.md` | StudyMaterials, generación IA |
| 04 | `04_BACKEND_BILLING_WEBHOOKS.md` | Billing, pagos, webhooks |
| 05 | `05_BACKEND_TEACHER_STUDENT.md` | Teacher, Student, analytics |
| 06 | `06_BACKEND_PREP_PLUS.md` | Prep+ catálogo, checkout, admin |
| 07 | `07_BACKEND_OTROS.md` | Notifications, Sharing, Media, Status |
| 08 | `08_FLUTTER_AUTH_BILLING.md` | Auth y pagos en la app |
| 09 | `09_FLUTTER_QUIZZES_PRACTICE_OFFLINE.md` | Quizzes, práctica, offline |
| 10 | `10_FLUTTER_TEACHER_STUDENT_GUEST.md` | Teacher, Student, Guest |
| 11 | `11_FLUTTER_OTROS.md` | Notifications, Profile, Shell, etc. |
| 12 | `12_E2E_MULTIPLATAFORMA.md` | Flujos cruzados y matriz por plataforma |

### Guías manuales paso a paso (para QA humano)

Si vas a ejecutar pruebas **a mano** en la app o en staging, usa la carpeta **[`manuales/`](manuales/00_COMO_EJECUTAR.md)**. Cada documento tiene instrucciones numeradas, casillas para marcar y enlaces al siguiente paso.

| Documento manual | Contenido |
|----------------|-----------|
| [`manuales/00_COMO_EJECUTAR.md`](manuales/00_COMO_EJECUTAR.md) | Cómo empezar, cuentas, orden de sesiones |
| [`manuales/01_REGISTRO_Y_LOGIN.md`](manuales/01_REGISTRO_Y_LOGIN.md) | Registro, login, OAuth |
| [`manuales/02_QUIZZES_Y_PRACTICA.md`](manuales/02_QUIZZES_Y_PRACTICA.md) | Quizzes y práctica online |
| [`manuales/03_PAGOS_Y_SUSCRIPCIONES.md`](manuales/03_PAGOS_Y_SUSCRIPCIONES.md) | Compras y webhooks Google Play |
| [`manuales/04_GENERACION_IA.md`](manuales/04_GENERACION_IA.md) | Generación con IA |
| [`manuales/05_DOCENTE_Y_ESTUDIANTE.md`](manuales/05_DOCENTE_Y_ESTUDIANTE.md) | Clases y tareas |
| [`manuales/06_PREP_PLUS.md`](manuales/06_PREP_PLUS.md) | Prep+ |
| [`manuales/07_COMPARTIR_Y_GUEST.md`](manuales/07_COMPARTIR_Y_GUEST.md) | Share codes y guest |
| [`manuales/08_PRACTICA_OFFLINE.md`](manuales/08_PRACTICA_OFFLINE.md) | Offline Android |
| [`manuales/09_NOTIFICACIONES_Y_PERFIL.md`](manuales/09_NOTIFICACIONES_Y_PERFIL.md) | Push, perfil |
| [`manuales/10_FLUJOS_COMPLETOS.md`](manuales/10_FLUJOS_COMPLETOS.md) | Recorridos E2E y sign-off |

---

## Matriz de prioridades

| Prioridad | Criterio | Ejemplos |
|-----------|----------|----------|
| **P0** | Seguridad, pagos, pérdida de datos, acceso no autorizado | Auth, webhooks, revocación suscripción, JWT, consentimiento parental |
| **P1** | Funcionalidad core del producto | Quizzes, práctica, teacher/student, Prep+, IA |
| **P2** | Secundario, UX, admin, landings | AppVersion, Status, drag-and-drop carpetas, analytics avanzados |

**Orden de ejecución recomendado:** P0 → P1 → P2. Dentro de cada fase, ejecutar primero tests automatizados existentes y luego casos manuales marcados como gap.

---

## Entornos de prueba

### Entorno local (desarrollo)

| Componente | Configuración |
|------------|---------------|
| API | `dotnet run --project src/CraftQuest.Api` |
| Flutter Web | `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000` |
| Flutter Android | Emulador o dispositivo con `--dart-define=API_BASE_URL=http://10.0.2.2:5000` |
| Base de datos | SQL Server local o Azure SQL de desarrollo |

### Entorno staging / producción

| Componente | URL típica |
|------------|------------|
| API producción | `https://api.craftquestai.com` |
| API Azure directa | `https://api-craftquestai-prod-*.azurewebsites.net` |
| Webhook Google Play | `POST /api/webhooks/google-play` |
| Flutter Web prod | Build con `--dart-define=API_BASE_URL=https://api.craftquestai.com` |

### Flags de configuración backend (`appsettings.json` / variables Azure)

| Flag | Valor en tests unitarios | Valor en QA manual local | Valor en staging/prod |
|------|--------------------------|--------------------------|------------------------|
| `Testing:UseInMemoryDatabase` | `true` (integración) | `false` | `false` |
| `Payments:UseMockPayments` | `true` (unit) | `true` para dev sin sandbox | `false` |
| `Payments:Webhooks:RequireVerification` | `false` (unit) | `true` en staging real | `true` |
| `Payments:Webhooks:GooglePubSubAudience` | — | URL del push endpoint | URL exacta del endpoint |
| `Email:Enabled` | `false` → `LoggingEmailSender` | `false` o SMTP de prueba | `true` |
| `Push:Enabled` | `false` → `LoggingPushSender` | `false` o FCM real | `true` |
| `Ai:UseGemini` | `false` en unit (heurística) | `true` con API key | `true` |
| `Media:StorageProvider` | `local` | `local` | `azure` en prod |

### Cuentas y sandboxes externos

| Servicio | Requisito para pruebas reales |
|----------|-------------------------------|
| **PayPal Sandbox** | `Payments:PayPal:ClientId/ClientSecret`, cuenta comprador sandbox |
| **Google Play** | Licencia de prueba en Play Console, cuenta tester, service account JSON |
| **App Store** | Sandbox tester, `.p8` key, `AppleEnvironment: Sandbox` |
| **Firebase (FCM)** | `Push:CredentialsPath` → `firebase-credentials.json`, proyecto `craftquestai` |
| **Gemini** | `Ai:GeminiApiKey` válida |

### Migraciones SQL pendientes antes de QA de billing

Ejecutar en Azure SQL antes de probar webhooks Google Play con `PaymentIssuePending`:

```sql
-- Documentacion/AlterUserSubscriptions_PaymentIssuePending.sql
```

---

## Ejecución de tests automatizados

### Backend (.NET / xUnit)

```powershell
# Todos los unit tests
dotnet test "tests/CraftQuest.UnitTests/CraftQuest.UnitTests.csproj"

# Tests de integración (WebApplicationFactory + EF InMemory)
dotnet test "tests/CraftQuest.IntegrationTests/CraftQuest.IntegrationTests.csproj"

# Con cobertura
dotnet test tests/CraftQuest.UnitTests --collect:"XPlat Code Coverage"

# Filtrar por clase
dotnet test tests/CraftQuest.UnitTests --filter "FullyQualifiedName~GooglePlayPubSubWebhookTests"
```

**Stack:** xUnit, EF Core InMemory, `WebApplicationFactory`, mocks manuales (sin Moq).

**Cobertura actual (~136 unit + 5 integration):** Auth, Billing, Payments (mock + Google Play webhook), Notifications, Sharing, Prep+ access, AI helpers, Practice helpers, Offline crypto.

### Flutter (`flutter_test`)

```powershell
cd mobile/craftquest_app
flutter test
flutter test test/features/auth/
flutter analyze
```

**Stack:** `flutter_test`, fakes manuales, `SharedPreferences.setMockInitialValues`. Sin `bloc_test`, `mocktail`, ni `integration_test/` aún.

**Cobertura actual (~36 tests):** AuthBloc offline, LoginPage smoke, billing model, offline order, practice sound prefs, AI upload zone, guest limit store, plugins smoke.

---

## Plantilla de caso de prueba manual

Copiar esta plantilla para cada caso nuevo o al registrar resultados:

```markdown
### [ID] Título del caso

| Campo | Valor |
|-------|-------|
| **ID** | DOM-NNN (ej. AUTH-001) |
| **Prioridad** | P0 / P1 / P2 |
| **Tipo** | Manual / Automatizado / Ambos |
| **Plataforma** | API / Android / iOS / Web / Desktop / Todas |
| **Automatizado** | Sí → `ruta/al/test.cs` / No → sugerido: `ruta/sugerida.cs` |
| **Precondiciones** | Usuario X autenticado, plan Y, datos Z en BD |
| **Pasos** | 1. ... 2. ... 3. ... |
| **Resultado esperado** | HTTP 200, campo X = Y, UI muestra Z |
| **Resultado actual** | ☐ Pass ☐ Fail ☐ N/A |
| **Ejecutado por / fecha** | |
| **Notas** | |
```

### Convención de IDs

| Prefijo | Dominio |
|---------|---------|
| AUTH | Autenticación |
| QUIZ | Quizzes y carpetas |
| PRAC | Práctica |
| GUEST | Modo invitado |
| IMP | Importación CQIF |
| AI | Generación IA |
| BILL | Billing y pagos |
| WH | Webhooks |
| TCH | Teacher |
| STU | Student |
| PREP | Prep+ |
| NOT | Notificaciones |
| SHR | Sharing |
| MED | Media |
| OFF | Offline |
| APP | App Flutter (UI) |
| E2E | Flujos cruzados |

---

## Criterios de aceptación global

Un release candidato se considera **aprobado para QA sign-off** cuando:

1. **P0:** 100% de casos ejecutados, 0 fallos abiertos.
2. **P1:** ≥ 95% ejecutados, fallos documentados con workaround o fix planificado.
3. **P2:** ≥ 80% ejecutados o marcados N/A con justificación.
4. **Automatizados:** `dotnet test` y `flutter test` en verde en CI (cuando exista pipeline).
5. **Regresión billing:** Todos los casos de `04_BACKEND_BILLING_WEBHOOKS.md` sección webhooks Google Play (tipos 1–13) verificados al menos una vez en staging.

---

## Registro de resultados

Crear una hoja de seguimiento (Excel/Notion) con columnas:

`ID | Documento | Prioridad | Plataforma | Estado | Bug ID | Fecha | Tester`

O marcar directamente en cada documento de dominio la columna **Resultado actual** de la plantilla.

---

## Roles de prueba recomendados

| Rol | Email / cuenta | Permisos |
|-----|----------------|----------|
| Usuario Free | `qa-free@...` | Plan free, sin Prep+ |
| Usuario Pro | `qa-pro@...` | Suscripción activa |
| Usuario Teacher | `qa-teacher@...` | Plan teacher + rol Teacher |
| Content Admin | `qa-admin@...` | Rol ContentAdmin (Prep+ admin) |
| Estudiante | `qa-student@...` | Miembro de clase del teacher |
| Guest | Sin cuenta | Token `X-Guest-Token` |

---

## Herramientas útiles

| Herramienta | Uso |
|-------------|-----|
| Postman / Insomnia | API manual, colección con JWT |
| Google Cloud Console | Pub/Sub → "Send test notification" |
| Play Console | Licencias de prueba, RTDN test |
| App Store Connect | Sandbox testers |
| Azure Log Stream | Logs de webhooks en producción |
| SQL Server Management Studio | Verificar `billing.UserSubscriptions`, `ProviderWebhookEvents` |
| Flutter DevTools | Debug UI, network |
