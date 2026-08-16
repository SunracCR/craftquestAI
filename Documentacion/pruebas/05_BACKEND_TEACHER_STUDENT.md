# 05 — Backend: Teacher, Student, Analytics

Controladores: `TeacherController` (`api/teacher`, política `Teacher`), `StudentController` (`api/student`).

Tests automatizados existentes:
- `TeacherReviewMapperTests.cs` (3)
- `AnalyticsSelectionRateTests.cs`, `DistractorAnalyticsAggregatorTests.cs`

Tests sugeridos:
- `tests/CraftQuest.UnitTests/Teacher/ClassServiceTests.cs`
- `tests/CraftQuest.UnitTests/Teacher/AssignmentServiceTests.cs`
- `tests/CraftQuest.UnitTests/Teacher/TeacherDashboardServiceTests.cs`
- `tests/CraftQuest.UnitTests/Teacher/TeacherReviewServiceTests.cs`
- `tests/CraftQuest.UnitTests/Student/StudentServiceTests.cs`

---

## Teacher — Dashboard

### TCH-001 — GET dashboard

| Prioridad | P1 |
| **Endpoint** | `GET /api/teacher/dashboard` |
| **Auth** | Rol Teacher |
| **Resultado esperado** | Stats: clases activas, assignments, actividad reciente |

### TCH-002 — Activity feed

| **Endpoint** | `GET /api/teacher/activity-feed` |

---

## Teacher — Clases

### TCH-010 — Listar clases

| **Endpoint** | `GET /api/teacher/classes?status=active` |
| **Resultado esperado** | Solo clases del docente; filtro archived |

### TCH-011 — Crear clase

| **Endpoint** | `POST /api/teacher/classes` |
| **Pasos** | `{ name, description? }` |
| **Resultado esperado** | classId; código de join generado |

### TCH-012 — Detalle de clase

| **Endpoint** | `GET /api/teacher/classes/{classId}` |

### TCH-013 — Actualizar clase

| **Endpoint** | `PATCH /api/teacher/classes/{classId}` |

### TCH-014 — Archivar / restaurar / eliminar

| **Endpoints** | `POST .../archive`, `POST .../restore`, `DELETE .../{classId}` |
| **Resultado esperado** | Archivada no aparece en active; restore revierte |

---

## Teacher — Miembros

### TCH-020 — Añadir miembro por email

| **Endpoint** | `POST /api/teacher/classes/{classId}/members` |
| **Pasos** | Email de estudiante registrado |
| **Resultado esperado** | Miembro pending o active según flujo |

### TCH-021 — Aprobar miembro

| **Endpoint** | `PATCH .../members/{userId}` |
| **Pasos** | `{ approved: true }` |

### TCH-022 — Eliminar miembro

| **Endpoint** | `DELETE .../members/{userId}` |

### TCH-023 — Usuario no-Teacher intenta acceder

| **Prioridad** | P0 |
| **Resultado esperado** | 403 Forbidden |

---

## Teacher — Assignments

### TCH-030 — Listar assignments de clase

| **Endpoint** | `GET /api/teacher/classes/{classId}/assignments` |

### TCH-031 — Crear assignment

| **Endpoint** | `POST /api/teacher/classes/{classId}/assignments` |
| **Pasos** | `{ quizId, title, dueDate?, options }` |
| **Resultado esperado** | assignmentId; visible para estudiantes de la clase |

### TCH-032 — Detalle assignment

| **Endpoint** | `GET /api/teacher/assignments/{assignmentId}` |

### TCH-033 — Actualizar assignment

| **Endpoint** | `PATCH /api/teacher/assignments/{assignmentId}` |

### TCH-034 — Cerrar assignment

| **Endpoint** | `POST .../close` |
| **Resultado esperado** | No nuevos intentos |

### TCH-035 — Archivar assignment

| **Endpoint** | `POST .../archive` |

### TCH-036 — Completion status

| **Endpoint** | `GET .../completion` |
| **Resultado esperado** | Lista estudiantes con % completado |

### TCH-037 — Analytics de assignment

| **Endpoint** | `GET .../analytics` |
| **Resultado esperado** | Scores agregados, distribución |

---

## Teacher — Analytics y revisión

### TCH-040 — Analytics de clase

| **Endpoint** | `GET /api/teacher/classes/{classId}/analytics` |

### TCH-041 — Analytics de quiz

| **Endpoint** | `GET /api/teacher/quizzes/{quizId}/analytics` |
| **Query** | `classId`, `assignmentId` opcionales |
| **Automatizado** | Parcial → `AnalyticsSelectionRateTests`, `DistractorAnalyticsAggregatorTests` |

### TCH-042 — Intentos de práctica del quiz

| **Endpoint** | `GET /api/teacher/quizzes/{quizId}/practice-attempts` |

### TCH-043 — Revisión de sesión

| **Endpoint** | `GET /api/teacher/practice-sessions/{sessionId}` |
| **Automatizado** | Parcial → `TeacherReviewMapperTests` |
| **Resultado esperado** | Respuestas del estudiante con correct/incorrect |

---

## Student — Vista estudiante

### STU-001 — Mis clases

| Prioridad | P1 |
| **Endpoint** | `GET /api/student/classes` |
| **Auth** | Estudiante miembro de al menos una clase |
| **Resultado esperado** | Clases donde es miembro aprobado |

### STU-002 — Mis assignments

| **Endpoint** | `GET /api/student/assignments` |
| **Resultado esperado** | Assignments activos con due dates |

### STU-003 — Mis intentos en assignment

| **Endpoint** | `GET /api/student/assignments/{assignmentId}/my-attempts` |

### STU-004 — Resumen de progreso

| **Endpoint** | `GET /api/student/assignments/{assignmentId}/my-summary` |

### STU-005 — Practicar assignment

| **Pasos** | `POST /api/practice-sessions` con assignmentId |
| **Resultado esperado** | Sesión vinculada al assignment; visible en analytics docente |

### STU-006 — Estudiante no miembro

| **Resultado esperado** | 403 al acceder assignment de otra clase |

---

## Flujo integrado Teacher ↔ Student

### E2E-TCH-001 — Ciclo completo clase

| Prioridad | P0 |
| **Pasos** | 1. Teacher crea clase. 2. Añade estudiante. 3. Crea assignment. 4. Estudiante practica y termina. 5. Teacher ve completion y revisa intento |
| **Resultado esperado** | Datos consistentes en dashboard, analytics y review |

---

## Checklist sign-off Teacher/Student

- [ ] CRUD clases y miembros
- [ ] Assignment create → student practice → teacher review
- [ ] Analytics reflejan intentos reales
- [ ] 403 para usuarios sin rol Teacher
- [ ] Archivado no rompe historial de intentos
