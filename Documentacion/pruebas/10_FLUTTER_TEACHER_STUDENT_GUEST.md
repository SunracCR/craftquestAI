# 10 — Flutter: Teacher, Student, Guest

Pantallas Teacher: `teacher_hub_page`, `teacher_dashboard_page`, `teacher_class_*`, `teacher_create_*`, `teacher_assignment_*`, `teacher_attempts_page`, `teacher_session_review_page`.

Pantallas Student: `student_assignments_page`, `student_assignment_detail_page`, `student_assignment_attempts_page`, `student_assignment_progress_page`.

Pantallas Guest: `guest_code_page`, `guest_shell_page`, `guest_practice_session_page`, `guest_result_page`, `guest_register_benefits_promo_page`.

Tests automatizados existentes:
- `test/core/guest/anonymous_practice_limit_store_test.dart` (límite 3/día)

Tests sugeridos:
- `test/features/guest/guest_session_cubit_test.dart`
- `test/features/teacher/teacher_repository_test.dart`
- `test/features/student/student_repository_test.dart`

---

## Teacher

### APP-TCH-001 — Tab Teacher visible

| Prioridad | P1 |
| **Precondiciones** | Plan Teacher activo |
| **Pantalla** | `main_shell_page.dart` |
| **Resultado esperado** | 4 tabs: Home, Prep+, Teacher, Perfil |

### APP-TCH-002 — Welcome overlay primera vez

| **Storage** | `teacher_welcome_overlay.dart` → SharedPreferences |
| **Resultado esperado** | Overlay dismissible; no reaparece |

### APP-TCH-003 — Dashboard

| **Pantalla** | `teacher_dashboard_page.dart` |
| **Resultado esperado** | Stats y actividad reciente cargados |

### APP-TCH-004 — Listar clases

| **Pantalla** | `teacher_class_list_page.dart` |
| **Pasos** | Ver activas y archivadas |

### APP-TCH-005 — Crear clase

| **Pantalla** | `teacher_create_class_page.dart` |
| **Resultado esperado** | Clase creada; código join visible |

### APP-TCH-006 — Detalle clase

| **Pantalla** | `teacher_class_detail_page.dart` |
| **Pasos** | Ver miembros, assignments, analytics link |

### APP-TCH-007 — Añadir / aprobar miembros

| **Pasos** | Invitar por email → aprobar pending |
| **Resultado esperado** | Estudiante aparece como activo |

### APP-TCH-008 — Archivar clase

| **Resultado esperado** | Mueve a archivadas; no elimina historial |

### APP-TCH-009 — Crear assignment

| **Pantalla** | `teacher_create_assignment_page.dart` |
| **Pasos** | Seleccionar quiz, fechas, opciones |
| **Resultado esperado** | Assignment visible en detalle clase |

### APP-TCH-010 — Detalle assignment

| **Pantalla** | `teacher_assignment_detail_page.dart` |
| **Pasos** | Ver completion, cerrar, archivar |

### APP-TCH-011 — Analytics assignment

| **Pantalla** | `teacher_assignment_analytics_page.dart` |

### APP-TCH-012 — Ver intentos estudiantes

| **Pantalla** | `teacher_attempts_page.dart` |

### APP-TCH-013 — Revisar sesión

| **Pantalla** | `teacher_session_review_page.dart` |
| **Resultado esperado** | Respuestas correctas/incorrectas por pregunta |

### APP-TCH-014 — Usuario sin plan Teacher

| **Resultado esperado** | Tab Teacher oculto o redirect a upgrade |

---

## Student

### APP-STU-001 — Ver assignments

| Prioridad | P1 |
| **Pantalla** | `student_assignments_page.dart` |
| **Acceso** | Home → Mis asignaciones |
| **Resultado esperado** | Lista pendientes/completadas |

### APP-STU-002 — Detalle assignment

| **Pantalla** | `student_assignment_detail_page.dart` |
| **Resultado esperado** | Instrucciones, due date, botón practicar |

### APP-STU-003 — Completar assignment

| **Pasos** | Iniciar práctica → finish |
| **Resultado esperado** | Progreso actualizado; visible para teacher |

### APP-STU-004 — Ver intentos previos

| **Pantalla** | `student_assignment_attempts_page.dart` |

### APP-STU-005 — Progreso de clase

| **Pantalla** | `student_assignment_progress_page.dart` |

### APP-STU-006 — Preferencia randomize

| **Storage** | `AssignmentRandomizePreferenceStore` |
| **Resultado esperado** | Preferencia persistida por assignment |

---

## Guest (sin cuenta)

### APP-GUEST-001 — Ingresar código

| Prioridad | P1 |
| **Pantalla** | `guest_code_page.dart` |
| **Pasos** | Introducir código de share/join válido |
| **Resultado esperado** | Navega a guest shell |

### APP-GUEST-002 — Guest shell

| **Pantalla** | `guest_shell_page.dart` |
| **Storage** | `GuestTokenStorage` → FlutterSecureStorage |
| **Resultado esperado** | Info visita; botón practicar |

### APP-GUEST-003 — Práctica guest completa

| **Pantalla** | `guest_practice_session_page.dart` |
| **Pasos** | Start → answer → finish |
| **Resultado esperado** | Resultados en `guest_result_page` |

### APP-GUEST-004 — Límite diario de canjes

| **Automatizado** | Sí → `anonymous_practice_limit_store_test.dart` |
| **Pasos** | Canjear 4 códigos en mismo día |
| **Resultado esperado** | Error limitReached en UI |

### APP-GUEST-005 — Promo registro post-práctica

| **Pantalla** | `guest_register_benefits_promo_page.dart` |
| **Resultado esperado** | CTA a registro |

### APP-GUEST-006 — Salir guest mode

| **Resultado esperado** | Token borrado; vuelve a login/código |

### APP-GUEST-007 — Deep link join (Web)

| **Launcher** | `join_launch.dart` |
| **Pasos** | Abrir `/join/{code}` en web |
| **Resultado esperado** | Entra a flujo guest o redeem |

---

## Flujo cruzado Teacher ↔ Student (manual E2E)

### APP-E2E-TS-001

| Prioridad | P0 |
| **Pasos** | 1. Teacher crea clase y assignment (app teacher). 2. Student ve assignment (app student). 3. Student practica y termina. 4. Teacher revisa intento en analytics/review |
| **Plataformas** | Probar en Android + Web mínimo |

---

## Checklist sign-off Teacher/Student/Guest

- [ ] Teacher: clase → assignment → analytics
- [ ] Student: ver y completar assignment
- [ ] Guest: código → practicar → resultado
- [ ] Límite 3 canjes/día verificado
- [ ] Tab Teacher solo con plan teacher
