# Azure SQL — rendimiento al iniciar práctica

Guía para reducir la latencia de la **primera** sesión de práctica tras inactividad (cuestionarios con 75+ preguntas).

## Síntoma

- Tras un rato sin usar la app, `POST /api/practice-sessions` tarda hasta ~30 s.
- Un segundo intento inmediato es mucho más rápido.
- Always On del App Service ya está activo.

Esto suele indicar **caché en frío del buffer pool de SQL** (páginas de `quiz.Questions`, `quiz.QuestionAnswerOptions`, etc. ya no están en memoria), no cold start de la app.

## Checklist en Azure Portal

### 1. Azure SQL — tier y configuración

1. Portal → **SQL databases** → base de datos de CraftQuest.
2. Anotar:
   - **Compute tier**: DTU, vCore provisioned o **serverless**.
   - **Max vCores / DTU** y **memoria** asociada.
3. Si es **serverless**:
   - Revisar **Auto-pause delay** y **Min vCores**.
   - Si aparece evento **Database resumed** en métricas al reproducir el lag, subir min vCores o desactivar auto-pause.
4. Si es **DTU Basic/S0** con poca RAM:
   - Considerar subir a **S2+** o **vCore General Purpose** (más buffer pool = menos lecturas a disco en frío).

### 2. Métricas durante una prueba lenta

Reproducir: esperar 30+ min sin practicar → iniciar cuestionario grande → en la misma ventana revisar:

| Métrica | Qué indica |
|---------|------------|
| **CPU percentage** | Carga de compilación/plan o resume |
| **Data IO percentage** | Lecturas a disco (buffer pool frío) |
| **Log IO percentage** | Escritura de snapshots (bulk insert) |
| **SQL instance CPU** | Límite del tier |

Si **Data IO** pica en la petición lenta y baja en el reintento, confirma caché en frío.

### 3. App Service

- **Always On**: activado (ya confirmado).
- **Health check path**: opcional `/health` (ready, incluye DB) para mantener instancia activa; no sustituye keep-warm de tablas en SQL.

### 4. Índices en producción

Ejecutar en Azure SQL:

```text
Documentacion/VerifyPracticeSnapshotIndexes.sql
```

Debe imprimir `OK` para:

- `IX_Questions_Quiz`
- `IX_QuestionAnswerOptions_Question`
- `IX_PracticeQuestionSnapshots_SessionOrder`
- `IX_PracticeAnswerOptionSnapshots_QuestionOrder`

### 5. Logs de la API tras despliegue

Con `Practice:LogStartSessionTiming=true`, buscar en Application Insights o logs:

```text
Practice session start completed quizId=... phases=[loadQuiz=..., loadQuestions=..., persistSnapshots=..., bulkCopyOptions=...]
```

Interpretación:

- **`loadQuestions` alto solo en frío** → buffer pool / tier SQL.
- **`bulkCopyOptions` alto** → volumen de snapshots (mitigado con inserción diferida ≥50 preguntas).
- **`connectionOpen` alto** → red o pool de conexiones.

## Cambios ya incluidos en código

| Componente | Efecto |
|------------|--------|
| `DatabaseKeepWarmHostedService` | Lecturas ligeras cada 2 min para mantener páginas calientes |
| `PracticeQuestionLoader` | Consultas indexadas en lugar de 4 `Include` con split |
| Inserción diferida de opciones | Sesión + nav + 1ª pregunta síncronos; resto en background |
| Instrumentación por fases | Diagnóstico en logs |

## Recomendación de tier (orientativa)

| Escenario | Sugerencia |
|-----------|------------|
| Producción con cuestionarios 75–150 preg | vCore GP **2 vCores** mínimo, o DTU **S3+** |
| Picos de 30 s tras inactividad persisten con keep-warm | Subir un nivel de compute o memoria |
| Serverless con auto-pause | Min vCores ≥ 0.5–1 y auto-pause ≥ 60 min, o migrar a provisioned |

## Validación

1. Desplegar API con los cambios.
2. Ejecutar script de índices en producción.
3. Esperar 30–60 min sin practicar el mismo quiz grande.
4. Iniciar práctica y comparar `totalMs` en logs con el baseline anterior (~30 s).
5. Objetivo: **&lt; 5 s** percibidos (primera pregunta visible) con inserción diferida; **&lt; 10 s** total HTTP en frío tras keep-warm + tier adecuado.
