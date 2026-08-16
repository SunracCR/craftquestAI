# 02 — Backend: Quizzes, Practice, Guest, Imports

Controladores: `QuizzesController`, `QuizFoldersController`, `QuizPracticePreferencesController`, `ShareCodesController`, `PracticeController`, `GuestController`, `QuestionImportsController`, `QuestionTypesController`, `OfflinePackagesController`.

Tests automatizados existentes:
- `AnswerGradingServiceTests.cs`, `PracticeSessionOrderingTests.cs`, `PracticeAnswerSelectionWriterTests.cs`
- `PracticeSessionCleanupTests.cs`
- `CqifImportTests.cs`, `HeuristicCqifNormalizationProviderTests.cs`
- `ShareCodeServiceTests.cs`
- `OfflinePackageCryptoServiceTests.cs`
- `CraftQuest.IntegrationTests/QuizDeleteTests.cs` (delete tras práctica)

Tests sugeridos:
- `tests/CraftQuest.UnitTests/Quizzes/QuizServiceTests.cs`
- `tests/CraftQuest.UnitTests/Practice/PracticeServiceTests.cs`
- `tests/CraftQuest.UnitTests/Guest/GuestServiceTests.cs`
- `tests/CraftQuest.IntegrationTests/Practice/PracticeFlowIntegrationTests.cs`

---

## Quizzes — CRUD

### QUIZ-001 — Crear quiz

| Prioridad | P1 |
| **Endpoint** | `POST /api/quizzes` |
| **Pasos** | POST `{ title, description?, language? }` autenticado |
| **Resultado esperado** | 201; quizId; estado draft; pertenece al usuario |

### QUIZ-002 — Listar mis quizzes

| **Endpoint** | `GET /api/quizzes` |
| **Resultado esperado** | Solo quizzes del usuario; paginación si aplica |

### QUIZ-003 — Detalle de quiz

| **Endpoint** | `GET /api/quizzes/{quizId}` |
| **Resultado esperado** | Metadatos + conteo preguntas; 404 si no es dueño |

### QUIZ-004 — Actualizar quiz (PATCH)

| **Endpoint** | `PATCH /api/quizzes/{quizId}` |
| **Pasos** | Cambiar título, publicar (`isPublished: true`) |
| **Resultado esperado** | Cambios persistidos; publicación valida mínimo de preguntas |

### QUIZ-005 — Eliminar quiz

| **Endpoint** | `DELETE /api/quizzes/{quizId}` |
| **Automatizado** | Parcial → `QuizDeleteTests`, `PracticeSessionCleanupTests` |
| **Precondiciones** | Quiz con sesiones de práctica completadas |
| **Resultado esperado** | 204; sesiones/snapshots limpiados |

### QUIZ-006 — Límite de quizzes por plan Free

| **Prioridad** | P0 |
| **Automatizado** | Parcial → `BillingServiceQuizModificationTests` |
| **Resultado esperado** | 402/403 al exceder límite del plan |

---

## Preguntas

### QUIZ-010 — Crear pregunta

| **Endpoint** | `POST /api/quizzes/{quizId}/questions` |
| **Pasos** | Crear single-choice, multiple-choice, true/false según tipos disponibles |
| **Resultado esperado** | questionId; opciones correctas marcadas |

### QUIZ-011 — Listar preguntas (autor)

| **Endpoint** | `GET /api/quizzes/{quizId}/questions` |

### QUIZ-012 — Actualizar pregunta

| **Endpoint** | `PUT /api/quizzes/{quizId}/questions/{questionId}` |

### QUIZ-013 — Eliminar pregunta

| **Endpoint** | `DELETE /api/quizzes/{quizId}/questions/{questionId}` |

### QUIZ-014 — Export PDF

| **Endpoint** | `GET /api/quizzes/{quizId}/export/pdf` |
| **Resultado esperado** | PDF descargable con preguntas |

---

## Carpetas

### FOLD-001 — CRUD carpetas

| **Endpoints** | `GET/POST /api/quiz-folders`, `GET/PATCH/DELETE /api/quiz-folders/{id}` |
| **Automatizado** | No → `QuizFolderServiceTests.cs` |

### FOLD-002 — Mover quiz a carpeta

| **Pasos** | PATCH quiz con folderId |
| **Resultado esperado** | Quiz aparece agrupado en listado |

---

## Preferencias de práctica

### PREF-001 — GET/PUT practice-preferences

| **Endpoints** | `GET/PUT /api/quizzes/{quizId}/practice-preferences` |
| **Pasos** | Configurar randomize, timer, passing score |
| **Automatizado** | No → `QuizPracticePreferenceServiceTests.cs` |

---

## Share codes (por quiz)

### SHR-Q01 — Crear/obtener share code

| **Endpoints** | `GET/POST /api/quizzes/{quizId}/share-code` |
| **Automatizado** | Parcial → `ShareCodeServiceTests` |

### SHR-Q02 — Invitar por email

| **Endpoint** | `POST /api/quizzes/{quizId}/invitations` |

---

## Practice — Sesiones online

### PRAC-001 — Iniciar sesión

| Prioridad | P0 |
| **Endpoint** | `POST /api/practice-sessions` |
| **Pasos** | `{ quizId, assignmentId? }` en quiz publicado |
| **Resultado esperado** | sessionId; snapshots de preguntas; orden según preferencias |
| **Automatizado** | Parcial → `PracticeSessionOrderingTests` |

### PRAC-002 — Obtener sesión activa

| **Endpoint** | `GET /api/practice-sessions/active?quizId=` |

### PRAC-003 — Obtener pregunta (snapshot)

| **Endpoint** | `GET /api/practice-sessions/{sessionId}/questions/{snapshotId}` |
| **Resultado esperado** | Pregunta sin revelar respuesta correcta |

### PRAC-004 — Enviar respuesta

| **Endpoint** | `POST .../questions/{snapshotId}/answer` |
| **Automatizado** | Parcial → `AnswerGradingServiceTests` |
| **Pasos** | Respuesta correcta e incorrecta |
| **Resultado esperado** | Feedback según modo; score parcial en multiple |

### PRAC-005 — Actualizar progreso

| **Endpoint** | `PATCH /api/practice-sessions/{sessionId}/progress` |

### PRAC-006 — Finalizar sesión

| **Endpoint** | `POST /api/practice-sessions/{sessionId}/finish` |
| **Resultado esperado** | Score final; sesión completed |

### PRAC-007 — Abandonar / forfeit

| **Endpoints** | `POST .../abandon`, `POST .../forfeit` |

### PRAC-008 — Mis intentos y revisión

| **Endpoints** | `GET .../by-quiz/{quizId}/my-attempts`, `GET .../{sessionId}/my-review` |

### PRAC-009 — Analytics personal

| **Endpoint** | `GET .../by-quiz/{quizId}/my-analytics` |

### PRAC-010 — Sesiones en progreso

| **Endpoint** | `GET /api/practice-sessions/in-progress` |

### PRAC-011 — Reanudar sesión interrumpida

| **Pasos** | Iniciar → responder parcial → GET active → continuar |
| **Resultado esperado** | Progreso preservado |

---

## Guest — Práctica sin cuenta

Header requerido: `X-Guest-Token`.

### GUEST-001 — Entrar como invitado

| **Endpoint** | `POST /api/guest/enter` |
| **Resultado esperado** | visitId + guest token |

### GUEST-002 — Flujo práctica completo

| **Endpoints** | start → answer → progress → finish |
| **Automatizado** | No → `GuestServiceTests.cs` |

### GUEST-003 — Límite de visitas / canjes

| **Resultado esperado** | Error al exceder límite diario |

### GUEST-004 — Salir (DELETE visit)

| **Endpoint** | `DELETE /api/guest/{visitId}` |

---

## Imports CQIF

### IMP-001 — Procesar texto/JSON

| **Endpoint** | `POST /api/quizzes/{quizId}/question-imports/process` |
| **Automatizado** | Parcial → `CqifImportTests` |

### IMP-002 — Procesar archivo Excel

| **Endpoint** | `POST .../process-file` |
| **Pasos** | Subir .xlsx válido |

### IMP-003 — Descargar plantilla Excel

| **Endpoint** | `GET /api/question-imports/excel-template` |

### IMP-004 — Preview importación

| **Endpoint** | `GET /api/question-imports/{importId}/preview` |

### IMP-005 — Confirmar importación

| **Endpoint** | `POST /api/question-imports/{importId}/confirm` |
| **Resultado esperado** | Preguntas creadas en quiz |

### IMP-006 — Normalización IA

| **Endpoint** | `POST .../ai-normalize` |
| **Precondiciones** | Créditos IA disponibles |
| **Resultado esperado** | Job IA encolado |

---

## Question types

### QT-001 — Listar tipos

| **Endpoint** | `GET /api/question-types` |
| **Resultado esperado** | Lista de tipos soportados (seed en integración) |

---

## Offline packages

### OFF-001 — Descargar paquete offline

| **Endpoint** | `GET /api/quizzes/{quizId}/offline-package` |
| **Automatizado** | Parcial → `OfflinePackageCryptoServiceTests` |
| **Resultado esperado** | Paquete cifrado; incluye preguntas y media refs |

### OFF-002 — Sync sesión offline

| **Endpoint** | `POST /api/practice-sessions/offline-sync` |
| **Pasos** | Enviar resultados practicados offline |
| **Resultado esperado** | Sesión registrada en servidor |

---

## Checklist sign-off

- [ ] CRUD quiz + preguntas completo
- [ ] Flujo práctica start → finish con scoring correcto
- [ ] Guest flow sin autenticación
- [ ] Import Excel end-to-end
- [ ] Offline package descarga + sync
- [ ] Límites de plan Free verificados
