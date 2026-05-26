# Generación de cuestionarios con IA desde material

## Resumen

Producto estrella que permite subir **PDF**, **DOCX** o **fotos de apuntes**, revisar el texto fuente, elegir alcance y parámetros pedagógicos, y generar un **borrador CQIF** revisable en `ImportPreviewPage` antes de confirmar en un cuestionario.

El cuestionario destino **solo se crea cuando la generación termina con éxito** (salvo si se indica `targetQuizId` para ampliar un cuestionario existente).

### Estrategia de generación (outline + chunks paralelos)

1. **Outline** (opcional, `gemini-2.5-flash-lite`): planifica N temas con `chunkIndex` y tipo sugerido.
2. **Chunks** (~3 800 palabras): cortes en `--- Page N ---` o párrafos; preguntas repartidas con residuo en el último chunk.
3. **Paralelo** (máx. 3 llamadas simultáneas): cada chunk genera su CQIF siguiendo el plan de outline.
4. **Merge**: concatena, deduplica por texto, asigna `externalId` y `order`.

Textos cortos (1 chunk) y &lt; 5 preguntas omiten outline. Config en `AiGeneration`: `UseOutlinePhase`, `ChunkTargetWordsPerRequest`, `MaxParallelChunkRequests`, `OutlineGeminiModel`.

## Requisitos de entorno

1. Ejecutar el script SQL: [`AlterStudyMaterials_AI_Generation.sql`](AlterStudyMaterials_AI_Generation.sql)
2. Configurar Gemini en desarrollo (no commitear la clave):

   - Copiar `src/CraftQuest.Api/appsettings.Development.local.json.example` → `appsettings.Development.local.json`
   - Pegar tu API key en `Ai:GeminiApiKey` (el archivo `.local.json` está en `.gitignore`)

   Producción: variable de entorno `Ai__GeminiApiKey` o secreto del host.

```json
"Ai": {
  "Enabled": true,
  "UseGemini": true,
  "GeminiApiKey": "YOUR_KEY",
  "GeminiModel": "gemini-2.5-flash",
  "GeminiFallbackModels": [ "gemini-2.5-flash-lite" ]
},
"AiGeneration": {
  "UseGemini": true,
  "AllowedImageExtensions": [ ".jpg", ".jpeg", ".png", ".webp" ],
  "MaxImagesPerMaterial": 15,
  "GenerationJobMaxAttempts": 2,
  "RetentionDays": 30
}
```

3. Reiniciar la API (el worker `AiProcessingHostedService` procesa extracción, generación y retención de materiales expirados).

## Flujo de usuario

1. **Home** → “Crear desde material” o **Detalle del cuestionario** → “Generar con IA”.
2. Subir PDF/DOCX o varias fotos (máx. 25 MB total; hasta 15 imágenes).
3. Esperar análisis (polling cada 2 s).
4. Si `requiresTextReview`: pantalla de **revisión de texto** (OCR con IA en fotos o edición manual).
5. Elegir rango de páginas (máx. 30 por generación) y tema opcional.
6. Elegir preset, tipos de pregunta, preguntas y dificultad; ver créditos estimados.
7. Generar → polling del job IA → **Vista previa de importación** → confirmar.

**Biblioteca:** desde el hub, “Ver biblioteca” reabre materiales guardados (retención 30 días si no están fijados).

## API

| Método | Ruta |
|--------|------|
| GET | `/api/study-materials` |
| POST | `/api/study-materials` |
| POST | `/api/study-materials/images` |
| GET | `/api/study-materials/{id}` |
| PATCH | `/api/study-materials/{id}/extracted-text` |
| POST | `/api/study-materials/{id}/run-ocr` |
| PATCH | `/api/study-materials/{id}/selection` |
| POST | `/api/study-materials/{id}/generate/estimate` |
| POST | `/api/study-materials/{id}/generate` |
| GET | `/api/ai/jobs/{aiJobId}` |

OpenAPI: [`CraftQuest_OpenAPI_MVP_v4.yaml`](CraftQuest_OpenAPI_MVP_v4.yaml) (tag `StudyMaterials`).

## Límites (config `AiGeneration`)

| Parámetro | Default |
|-----------|---------|
| MaxUploadBytes | 25 MB |
| MaxPagesPerMaterial | 120 |
| MaxPagesPerGeneration | 30 |
| MaxWordsPerGeneration | 12 000 |
| MaxQuestionsPerGeneration | 40 |
| MaxImagesPerMaterial | 15 |
| RetentionDays | 30 |

## Créditos IA

`créditos = base (2) + ceil(preguntas / 10) × 1` (ajustado a preguntas realmente generadas al finalizar).

Códigos de error: `AI_CREDITS_INSUFFICIENT`, `AI_NOT_CONFIGURED`, `GENERATION_ALREADY_IN_PROGRESS`, `MATERIAL_NEEDS_OCR`, `GENERATION_SCOPE_EMPTY`.

## Tipos de pregunta

`single_choice`, `multiple_choice`, `true_false` (selector en la app). Las preguntas confirmadas desde import `SourceType = ai` llevan `IsGeneratedByAi = true`.

## PDF escaneado y fotos

- PDF con poco texto: `needsOcr = true` → revisión manual o texto editado (`EditedExtractedText`).
- Fotos: subida multi-imagen → OCR con Gemini (`POST run-ocr`) o texto pegado manualmente.

## Troubleshooting

| Síntoma | Acción |
|---------|--------|
| Job en `pending` mucho tiempo | Verificar que la API esté en ejecución (hosted service) |
| 503 / `AI_NOT_CONFIGURED` | Configurar `GeminiApiKey` y `UseGemini: true` |
| 404 / `AI_GEMINI_MODEL_UNAVAILABLE` | Usar `GeminiModel`: `gemini-2.5-flash` (o más reciente) y reiniciar la API |
| 503 / `AI_GEMINI_OVERLOADED` | Demanda alta en Google; reintentos inmediatos (4) + cola diferida (2/5/15 min); créditos solo al éxito |
| Reintento manual | `POST /api/ai/jobs/{id}/retry` tras `failed`; no consume créditos hasta completar |

### SQL adicional (reintentos diferidos)

Ejecutar `Documentacion/AlterAiJobs_DeferredRetry.sql` en la base de datos.
| `GENERATION_ALREADY_IN_PROGRESS` | Esperar el job anterior o cancelar desde admin |
| Pocas preguntas importables | Revisar límite del plan (`importableQuestionCount` en preview) |
| Material desapareció | Retención 30 días; volver a subir o fijar material (futuro) |
