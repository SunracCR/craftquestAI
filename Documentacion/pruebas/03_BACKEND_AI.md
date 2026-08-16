# 03 — Backend: StudyMaterials, IA, generación de quizzes

Controladores: `StudyMaterialsController`, `AiController`, `QuestionImportsController` (ai-normalize).

Background job: `AiProcessingHostedService` (extracción texto, jobs generación, expiración materiales).

Tests automatizados existentes:
- `Ai/QuizGenerationCapacityCalculatorTests.cs` (5)
- `Ai/QuizGenerationQuestionMergerTests.cs` (2)
- `Ai/StudyMaterialTextChunkerTests.cs` (4)
- `StudyMaterials/StudyMaterialLanguageResolverTests.cs` (3)
- `StudyMaterials/StudyMaterialStreamHelperTests.cs` (2)
- `StudyMaterialOutlineHelperTests.cs` (4)
- `QuizGenerationPresetApplierTests.cs` (2)
- `HeuristicCqifNormalizationProviderTests.cs` (2)

Tests sugeridos:
- `tests/CraftQuest.UnitTests/Ai/AiServiceTests.cs`
- `tests/CraftQuest.UnitTests/Ai/QuizGenerationServiceTests.cs`
- `tests/CraftQuest.UnitTests/StudyMaterials/StudyMaterialServiceTests.cs`
- `tests/CraftQuest.IntegrationTests/Ai/QuizGenerationIntegrationTests.cs`

---

## Study Materials — Upload y gestión

### AI-001 — Subir material PDF

| Prioridad | P1 |
| **Endpoint** | `POST /api/study-materials` (multipart) |
| **Precondiciones** | Usuario con créditos IA |
| **Pasos** | Subir PDF < MaxUploadBytes |
| **Resultado esperado** | studyMaterialId; estado processing/pending extraction |

### AI-002 — Subir material DOCX

| **Pasos** | Subir DOCX válido |
| **Resultado esperado** | Extracción de texto encolada |

### AI-003 — Archivo demasiado grande

| **Prioridad** | P1 |
| **Pasos** | Subir archivo > `AiGeneration:MaxUploadBytes` |
| **Resultado esperado** | 413/400 error claro |

### AI-004 — Listar materiales

| **Endpoint** | `GET /api/study-materials` |
| **Resultado esperado** | Solo materiales del usuario; estados correctos |

### AI-005 — Detalle de material

| **Endpoint** | `GET /api/study-materials/{id}` |

### AI-006 — Editar texto extraído

| **Endpoint** | `PATCH .../extracted-text` |
| **Pasos** | Corregir texto OCR manualmente |
| **Resultado esperado** | Texto actualizado; usable para generación |

### AI-007 — Actualizar selección de texto

| **Endpoint** | `PATCH .../selection` |
| **Pasos** | Seleccionar rango de páginas/sección para generar |

### AI-008 — Eliminar material

| **Endpoint** | `DELETE /api/study-materials/{id}` |

---

## Estimación y generación

### AI-010 — Estimar costo de generación

| **Endpoint** | `POST .../generate/estimate` |
| **Automatizado** | Parcial → `QuizGenerationCapacityCalculatorTests` |
| **Resultado esperado** | Créditos estimados, preguntas sugeridas, timeout estimado |

### AI-011 — Iniciar generación de quiz

| Prioridad | P0 |
| **Endpoint** | `POST .../generate` |
| **Precondiciones** | Material con texto extraído; créditos suficientes |
| **Pasos** | POST con parámetros (questionCount, types, language) |
| **Resultado esperado** | aiJobId; job en estado queued/processing; créditos reservados/descontados |

### AI-012 — Insuficientes créditos IA

| **Prioridad** | P0 |
| **Automatizado** | Parcial → `BillingServiceCreditTests`, `EnsureHasAiCreditsAsync` |
| **Resultado esperado** | 402 PAYMENT_REQUIRED o equivalente |

### AI-013 — PaymentIssuePending bloquea IA

| **Prioridad** | P0 |
| **Precondiciones** | Suscripción con `PaymentIssuePending=true` (webhook tipo 5/6) |
| **Resultado esperado** | 402 `PAYMENT_ISSUE_PENDING` |
| **Automatizado** | Sí → `BillingServiceGooglePlayWebhookTests` |

---

## Jobs IA (AiController)

### AI-020 — Listar jobs

| **Endpoint** | `GET /api/ai/jobs` |
| **Pasos** | Filtrar inbox, completed, failed |

### AI-021 — Detalle de job

| **Endpoint** | `GET /api/ai/jobs/{aiJobId}` |
| **Resultado esperado** | Progreso, estado, errores, quizId destino si completado |

### AI-022 — Reintentar job fallido

| **Endpoint** | `POST /api/ai/jobs/{aiJobId}/retry` |
| **Precondiciones** | Job en failed con attempts < max |
| **Resultado esperado** | Job reencolado |

### AI-023 — Limpiar historial inbox

| **Endpoint** | `DELETE /api/ai/jobs/inbox-history` |

### AI-024 — Normalizar formato pregunta

| **Endpoint** | `POST /api/ai/question-format/normalize` |
| **Automatizado** | Parcial → `HeuristicCqifNormalizationProviderTests` |
| **Pasos** | Texto crudo → formato CQIF |
| **Resultado esperado** | JSON CQIF válido; consume créditos |

---

## Background job — AiProcessingHostedService

### AI-030 — Extracción automática de PDF

| **Tipo** | Manual / integración |
| **Pasos** | Subir PDF → esperar polling (≤ StaleProcessingMinutes) |
| **Resultado esperado** | Material pasa a `ready`; texto extraído en BD |

### AI-031 — Generación completa end-to-end

| **Pasos** | estimate → generate → poll job → confirmar quiz importado |
| **Precondiciones** | `Ai:GeminiApiKey` válida O heurística en dev |
| **Resultado esperado** | Quiz borrador con N preguntas; job completed |

### AI-032 — Job timeout

| **Pasos** | Simular documento muy grande o API lenta |
| **Resultado esperado** | Job failed tras `GenerationJobTimeoutMinutes`; créditos revertidos si aplica |

### AI-033 — Expiración de materiales

| **Precondiciones** | Material más antiguo que `RetentionDays` |
| **Resultado esperado** | Material expirado/eliminado por job |

### AI-034 — Reintentos diferidos

| **Pasos** | Forzar fallo transitorio Gemini |
| **Resultado esperado** | Reintentos según `DeferredRetryDelayMinutes` |

---

## Gemini vs heurística

### AI-040 — Generación con Gemini activo

| **Config** | `Ai:UseGemini=true`, API key válida |
| **Resultado esperado** | Preguntas generadas vía `GeminiQuizGenerationProvider` |

### AI-041 — Fallback sin API key

| **Config** | `Ai:GeminiApiKey=""` |
| **Resultado esperado** | 503 o fallback heurístico según endpoint |

### AI-042 — Chunking de documentos largos

| **Automatizado** | Sí → `StudyMaterialTextChunkerTests` |
| **Pasos** | Documento > ChunkTargetWords |
| **Resultado esperado** | Múltiples chunks; merge sin duplicados (`QuizGenerationQuestionMergerTests`) |

### AI-043 — Fase outline

| **Config** | `AiGeneration:UseOutlinePhase=true` |
| **Resultado esperado** | Outline generado antes de preguntas |

---

## Import IA (QuestionImports)

### AI-050 — ai-normalize en import batch

| **Endpoint** | `POST /api/question-imports/{importId}/ai-normalize` |
| **Resultado esperado** | Job normalización; preview actualizado |

---

## Checklist sign-off IA

- [ ] Upload PDF y DOCX con extracción exitosa
- [ ] Generación completa produce quiz importable
- [ ] Créditos descontados correctamente
- [ ] Bloqueo por PaymentIssuePending verificado
- [ ] Retry de job fallido funciona
- [ ] Normalización CQIF (heurística + Gemini si disponible)
- [ ] `dotnet test --filter Ai` en verde
