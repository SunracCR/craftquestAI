# 09 — Flutter: Quizzes, Práctica, Offline, Imports, IA

Pantallas principales: `quiz_list_page`, `quiz_detail_page`, `create_quiz_page`, `quiz_questions_page`, `add_question_page`, `practice_session_page`, `practice_result_page`, `my_practice_attempts_page`, `offline_*`, `import_*`, `ai_generation/*`.

Tests automatizados existentes:
- `test/features/practice/practice_sound_preference_store_test.dart`
- `test/features/offline_practice/offline_order_generator_test.dart`
- `test/features/ai_generation/study_material_upload_zone_test.dart`
- `test/core/widgets/app_answer_tile_test.dart`

Tests sugeridos:
- `test/features/quizzes/quiz_repository_test.dart`
- `test/features/offline_practice/offline_practice_session_cubit_test.dart`
- `test/features/offline_practice/offline_local_grader_test.dart`
- `test/features/practice/practice_session_page_test.dart`
- `test/features/imports/import_repository_test.dart`

---

## Quizzes — CRUD

### APP-QUIZ-001 — Listar quizzes y carpetas

| Prioridad | P1 |
| **Pantalla** | `quiz_list_page.dart` |
| **Pasos** | Abrir tab Home → Mis quizzes |
| **Resultado esperado** | Lista con carpetas; búsqueda funciona |

### APP-QUIZ-002 — Crear quiz

| **Pantalla** | `create_quiz_page.dart` |
| **Resultado esperado** | Quiz creado; navega a detalle |

### APP-QUIZ-003 — Detalle y publicar

| **Pantalla** | `quiz_detail_page.dart` (~1600 líneas — hub central) |
| **Pasos** | Añadir preguntas → publicar |
| **Resultado esperado** | Estado published; botón practicar habilitado |

### APP-QUIZ-004 — Gestionar preguntas

| **Pantallas** | `quiz_questions_page`, `add_question_page` |
| **Pasos** | Crear single/multiple; subir imagen (media) |
| **Resultado esperado** | Preguntas guardadas; imagen visible |

### APP-QUIZ-005 — Drag carpetas (Web/Desktop)

| **Plataforma** | Web, Windows, macOS, Linux |
| **Widget** | `quiz_folder_grouped_list.dart` |
| **Resultado esperado** | Reordenar/mover entre carpetas |

### APP-QUIZ-006 — Export PDF

| **Pasos** | Quiz detail → export |
| **Resultado esperado** | Archivo PDF descargado |

### APP-QUIZ-007 — Límite plan Free

| **Resultado esperado** | Diálogo upgrade al exceder límite |

---

## Práctica online

### APP-PRAC-001 — Iniciar práctica

| Prioridad | P0 |
| **Pantalla** | `practice_session_page.dart` |
| **Pasos** | Quiz detail → Practicar |
| **Resultado esperado** | Primera pregunta; navegación next/prev |

### APP-PRAC-002 — Responder preguntas

| **Widget** | `AppAnswerTile` |
| **Automatizado** | Parcial → `app_answer_tile_test.dart` |
| **Pasos** | Single y multiple choice |

### APP-PRAC-003 — Timer y sonidos

| **Storage** | `PracticeSoundPreferenceStore` |
| **Automatizado** | Sí → `practice_sound_preference_store_test.dart` |
| **Resultado esperado** | Timer cuenta; SFX on/off persistido |

### APP-PRAC-004 — Reanudar sesión

| **Pasos** | Abandonar app mid-session → reabrir |
| **Resultado esperado** | Diálogo resume; progreso preservado |

### APP-PRAC-005 — Finalizar y ver resultados

| **Pantalla** | `practice_result_page.dart` |
| **Resultado esperado** | Score, tiempo, opción revisar |

### APP-PRAC-006 — Historial de intentos

| **Pantalla** | `my_practice_attempts_page.dart` |

### APP-PRAC-007 — Práctica desde assignment

| **Pasos** | Student assignment → iniciar práctica |
| **Resultado esperado** | Sesión vinculada a assignment |

---

## Offline practice

**No soportado en Web** (`OfflinePlatformSupport`).

### APP-OFF-001 — Descargar quiz offline

| Prioridad | P1 |
| **Pantalla** | `offline_downloads_page.dart` |
| **Plataforma** | Android, iOS, Desktop |
| **Pasos** | Quiz detail → Descargar offline |
| **Resultado esperado** | Paquete en SQLite; icono offline en lista |

### APP-OFF-002 — Practicar sin conexión

| **Pantalla** | `offline_practice_session_page.dart` |
| **Pasos** | Modo avión → iniciar sesión offline |
| **Storage** | SQLite checkpoints + secure keys |
| **Automatizado** | Parcial → `offline_order_generator_test.dart` |

### APP-OFF-003 — Revisión offline

| **Pantalla** | `offline_practice_review_page.dart` |
| **Resultado esperado** | Score local correcto |

### APP-OFF-004 — Sync al reconectar

| **Pasos** | Completar offline → restaurar red |
| **Resultado esperado** | `OfflineSyncManager` sube resultados; visible en intentos online |

### APP-OFF-005 — Web muestra mensaje no soportado

| **Plataforma** | Web |
| **Resultado esperado** | UI informativa; no crash |

### APP-OFF-006 — Eliminar descarga

| **Pasos** | Offline downloads → eliminar |
| **Resultado esperado** | Paquete borrado de SQLite y disco |

---

## Imports

### APP-IMP-001 — Import Excel

| **Pantalla** | `excel_import_page.dart` |
| **Plataforma** | Todas (file picker distinto web vs móvil) |
| **Pasos** | Seleccionar .xlsx → preview → confirmar |

### APP-IMP-002 — Pegar texto CQIF

| **Pantalla** | `import_questions_page.dart` |

### APP-IMP-003 — Preview editable

| **Pantalla** | `import_preview_page.dart` |

---

## Generación IA

### APP-AI-001 — Hub generación

| **Pantalla** | `ai_generation_hub_page.dart` |

### APP-AI-002 — Subir material

| **Pantalla** | `study_material_upload_page.dart` |
| **Automatizado** | Parcial → `study_material_upload_zone_test.dart` |
| **Plataforma** | File picker web vs móvil |

### APP-AI-003 — Pipeline completo

| **Pantallas** | outline → review text → parameters → progress |
| **Pasos** | Subir PDF → configurar → esperar polling → importar borrador |
| **Resultado esperado** | Quiz borrador creado con preguntas IA |

### APP-AI-004 — Biblioteca materiales

| **Pantalla** | `ai_generation_materials_library_page.dart` |

### APP-AI-005 — Actividad / historial jobs

| **Pantalla** | `ai_activity_page.dart` |

### APP-AI-006 — Sin créditos / payment pending

| **Resultado esperado** | Diálogo upgrade o error pago pendiente |

---

## Analytics

### APP-AN-001 — Analytics de quiz

| **Pantalla** | `quiz_analytics_page.dart` |
| **Modos** | Global (autor) vs personal (estudiante) |

---

## Checklist sign-off Quizzes/Practice/Offline

- [ ] CRUD quiz completo en móvil
- [ ] Práctica online start → finish
- [ ] Offline download → practice → sync (Android)
- [ ] Web: offline bloqueado gracefully
- [ ] Import Excel end-to-end
- [ ] Generación IA end-to-end (con créditos)
- [ ] Drag carpetas en Web
