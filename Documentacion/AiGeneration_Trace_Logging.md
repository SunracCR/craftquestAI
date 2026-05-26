# Bitácora temporal — generación IA

Diagnóstico activo mientras se investiga el cuestionario con 0 preguntas.

## Activar / desactivar

`appsettings.json` → sección `AiGeneration`:

```json
"EnableAiGenerationTraceLogging": true,
"TraceLogDirectory": "logs/ai-gen-trace",
"TraceMaxLoggedCharacters": 12000
```

Pon `EnableAiGenerationTraceLogging` en `false` cuando ya no haga falta.

## Dónde mirar (no está en la terminal de Flutter)

1. **Consola donde corre `dotnet run`** (CraftQuest.Api) — al arrancar verás:
   `AI generation trace ENABLED. Log files: ...\logs\ai-gen-trace\{jobId}.log`
2. **Al iniciar cada job** — línea `LogWarning` con la ruta completa del archivo.
3. **Archivo por job** — carpeta:
   `c:\Users\cperaza_ga\Proyectos\CraftQuest\src\CraftQuest.Api\logs\ai-gen-trace\`
   Nombre: `{jobId sin guiones}.log` (ej. job `A1CF8039-F923-...` → `a1cf8039f9234f0783d876e8210c464f.log`).

Cada etapa registra: parámetros, prompts enviados a Gemini, respuestas (truncadas), conteo de preguntas tras parseo, sanitize, merge e import (filas válidas/errores).

## Etapas típicas

| Stage | Significado |
|-------|-------------|
| `job.input` | Parámetros y tamaño del SOURCE |
| `outline` / `outline.skip` | Plan de preguntas (flash-lite) |
| `chunk.single` / `chunks.parallel` | Llamadas de generación CQIF |
| `post-gemini` | Documento tras Gemini, antes de filtrar tipos |
| `sanitize` | Preguntas eliminadas por tipo no permitido |
| `import.populate` | Validación CQIF fila a fila |
| `import.batch` | Resumen del batch |
| `job.failed` | Error final |

## Códigos nuevos (job fallido en lugar de quiz vacío)

- `AI_GENERATION_NO_VALID_QUESTIONS` — Gemini devolvió tipos no permitidos y sanitize dejó 0.
- `AI_GENERATION_IMPORT_EMPTY` — Hay preguntas en JSON pero ninguna pasa validación CQIF.

Cuando el problema esté resuelto, desactivar trace y eliminar `AiGenerationTraceContext` y referencias.
