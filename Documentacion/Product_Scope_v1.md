# Alcance producto v1 — notas de backlog

Documento de referencia para ítems #21 y #22 de la lista maestra.

## Justificaciones (RF-JUS-001) — #21

**Estado en v1:** Las preguntas pueden llevar texto de justificación y fuentes al crear/editar. En práctica del estudiante la visibilidad queda en `never` (no se muestra al alumno tras el intento). La revisión docente sí muestra la justificación en el detalle del intento.

**Fuera de v1:** Selector «cuándo mostrar» (`after_attempt`, etc.), flujo de aprobación y estados de justificación en UI de estudiante.

## InstitutionAdmin (RF-USR-002) — #22

**Estado en v1:** Rol `institution_admin` existe en BD y etiquetas de UI. No hay módulo de organización, sedes, cupos ni permisos institucionales.

**Fuera de v1:** Panel InstitutionAdmin, gestión multi-sede y facturación institucional self-serve (el plan `institution` se ofrece como «Contactar ventas»).

## Analítica por distractor (RF-ANA-001) — #23

**Estado en v1:**

| Dimensión | Cómo se mide |
|-----------|----------------|
| **AnswerOptionId** | Al finalizar práctica (no invitados) se incrementa `AnswerOptionStats.SelectedCount`; en vistas con alcance se recalcula desde snapshots (`WasSelected`). |
| **Pregunta** | `QuestionStats` + `QuestionAnalyticsDto` (intentos, aciertos, omisiones). |
| **Quiz** | `GET /api/teacher/quizzes/{quizId}/analytics` — agregado global desde tablas de stats. |
| **Clase** | Mismo endpoint con `?classId=` — solo sesiones de esa clase (asignaciones de la clase o `ClassId` en sesión). |
| **Asignación** | Analítica de tarea incluye `distractorQuestions` (top preguntas difíciles de esa tarea); quiz con `?assignmentId=` para el mismo alcance. |

**UI:** Analítica del cuestionario (detalle del quiz); analítica de tarea con sección «Selección por opción»; pestaña Analítica de clase (resumen de notas/completitud, no barras por opción — usar analítica de tarea o quiz con `classId`).

**Fuera de v1:** Export CSV, comparativas entre clases, telemetría Application Insights para eventos de distractor (ver doc de App Insights).

## Refresh token en cliente (lista #24 / #25)

**Estado en v1:**

| Ítem | Comportamiento |
|------|----------------|
| **#24** | `AuthInterceptor` (Dio): ante **401** llama `POST /api/auth/refresh`, guarda tokens y reintenta la petición original. Usa un `Dio` auxiliar sin interceptor para evitar bucles. |
| **#25** | Si el refresh falla: borra tokens, `SessionExpiredNotifier` → snackbar i18n y `AuthBloc` vuelve al login. |

**API:** `POST /api/auth/refresh` con `{ "refreshToken": "..." }` → `{ accessToken, refreshToken, ... }` (camelCase).

**Prueba manual:** deja la app abierta hasta caducar el access token y realiza una acción autenticada; no debería pedir login si el refresh sigue válido.
