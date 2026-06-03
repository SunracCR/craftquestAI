# Importación masiva por Excel (CraftQuest)

## Endpoints

| Método | Ruta | Uso |
|--------|------|-----|
| GET | `/api/question-imports/excel-template?language=es` | Descarga plantilla `.xlsx` (`language`: `es`, `en`, `pt`) |
| POST | `/api/quizzes/{quizId}/question-imports/process-file` | Sube archivo (`multipart`: `file`, `sourceType=xlsx`) |
| GET | `/api/question-imports/{importId}/preview` | Vista previa |
| POST | `/api/question-imports/{importId}/confirm` | Confirma importación |

## Columnas de la plantilla (fila 1)

| Columna | Obligatorio | Ejemplo |
|---------|-------------|---------|
| Pregunta | Sí | ¿Capital de Francia? |
| Tipo | Sí | Desplegable en la plantilla: `single_choice`, `multiple_choice`, `true_false`, `image_choice`, `image_based_question` |
| Opción A … E | Según tipo | Texto de cada alternativa |
| Respuesta correcta | Sí | `B` o `A\|C` (múltiple) |
| Puntos | No | `1` |
| Sección | No | Geografía |
| Justificación | No | Texto explicativo de la respuesta correcta (opcional) |

## Tipos admitidos

- `single_choice` (por defecto si Tipo vacío)
- `multiple_choice`
- `true_false` (si faltan opciones, se generan Verdadero/Falso)
- `image_choice` — importa texto y opciones; **sin imágenes** (se añaden en la app)
- `image_based_question` — igual; se crea el hueco `QUESTION_IMAGE` para la imagen de la pregunta

## App Flutter

Menú del cuestionario → **Importar preguntas** → Excel o TXT/JSON.
