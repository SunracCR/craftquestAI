# Pruebas manuales — Quizzes y práctica

**Plataformas:** Android, Web (prueba ambas)  
**Tiempo total:** 60–90 min  
**Cuenta:** Usuario logueado (Free o Pro)

---

## M-QUIZ-01 — Crear un quiz nuevo

**Prioridad:** P1 · **Tiempo:** ~5 min

### Pasos

1. Inicia sesión.
2. En **Home**, entra a **Mis quizzes** (o equivalente).
3. Toca **Crear quiz** / botón **+**.
4. Título: `QA Quiz Manual 2026`
5. Descripción (opcional): `Prueba manual`
6. Guarda / crea.

### Deberías ver
- [ ] Quiz aparece en la lista
- [ ] Estado **borrador** / no publicado aún

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-QUIZ-02 — Añadir preguntas (single y multiple choice)

**Prioridad:** P0 · **Tiempo:** ~15 min

### Pasos

1. Abre el quiz creado en M-QUIZ-01.
2. Entra a **Preguntas** / gestionar preguntas.
3. **Pregunta 1 — Una sola respuesta:**
   - Texto: `¿Capital de Francia?`
   - Tipo: opción única
   - Opciones: A) París ✓, B) Lyon, C) Marsella
4. Guarda.
5. **Pregunta 2 — Varias respuestas:**
   - Texto: `Selecciona números pares`
   - Tipo: múltiple
   - Opciones: 2 ✓, 4 ✓, 3, 5
6. Guarda.
7. Repite hasta tener **al menos 5 preguntas** (puedes duplicar formato).

### Deberías ver
- [ ] Cada pregunta guardada sin error
- [ ] Contador de preguntas actualizado en detalle del quiz

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-QUIZ-03 — Publicar el quiz

**Prioridad:** P0 · **Tiempo:** ~3 min

### Pasos

1. En el **detalle del quiz**, busca **Publicar** o cambiar estado a publicado.
2. Confirma si hay diálogo.
3. Verifica que el estado cambió.

### Deberías ver
- [ ] Estado **Publicado**
- [ ] Botón **Practicar** habilitado

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-PRAC-01 — Practicar online (sesión completa)

**Prioridad:** P0 · **Tiempo:** ~15 min

### Pasos

1. Desde el detalle del quiz publicado, toca **Practicar**.
2. Responde la **primera pregunta** (elige una opción).
3. Avanza a la siguiente pregunta.
4. Responde **correctamente** al menos 2 preguntas y **incorrectamente** 1.
5. Completa todas las preguntas hasta el final.
6. Toca **Finalizar** / terminar sesión.
7. Revisa la pantalla de **resultados**.

### Deberías ver
- [ ] Navegación entre preguntas fluida
- [ ] Puntuación coherente con tus respuestas
- [ ] Pantalla de resultados con score y opción de revisar (si existe)

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-PRAC-02 — Reanudar sesión interrumpida

**Prioridad:** P1 · **Tiempo:** ~8 min

### Pasos

1. Inicia una **nueva** práctica del mismo quiz.
2. Responde **2 preguntas** y **no** termines.
3. Cierra la app completamente (quítala de recientes).
4. Abre la app de nuevo.
5. Vuelve al quiz e intenta practicar o continuar.

### Deberías ver
- [ ] La app ofrece **continuar** la sesión anterior **o** muestra sesión en progreso
- [ ] El progreso (pregunta actual) se conserva

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-PRAC-03 — Ver historial de intentos

**Prioridad:** P1 · **Tiempo:** ~5 min

### Pasos

1. En detalle del quiz, abre **Mis intentos** / historial.
2. Localiza el intento de M-PRAC-01.

### Deberías ver
- [ ] Lista con fecha, score o estado
- [ ] Puedes abrir revisión del intento (respuestas correctas/incorrectas)

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-QUIZ-04 — Importar preguntas desde Excel

**Prioridad:** P1 · **Tiempo:** ~15 min  
**Plataforma:** Web o Android

### Antes de empezar
- [ ] Descarga la plantilla Excel desde la app (Importar → plantilla) **o** usa un `.xlsx` válido CQIF

### Pasos

1. Crea un quiz borrador o usa uno existente.
2. Entra a **Importar preguntas** → **Excel**.
3. Selecciona el archivo `.xlsx`.
4. Revisa la **vista previa** de preguntas.
5. Confirma la importación.
6. Verifica en la lista de preguntas.

### Deberías ver
- [ ] Preview muestra preguntas parseadas
- [ ] Tras confirmar: preguntas añadidas al quiz

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-QUIZ-05 — Límite del plan Free (opcional)

**Prioridad:** P1 · **Tiempo:** ~10 min  
**Cuenta:** plan **Free**

### Pasos

1. Con cuenta Free, intenta crear **más quizzes** de los permitidos (consulta límite en Perfil o intenta hasta que falle).
2. O intenta añadir más preguntas del límite por quiz.

### Deberías ver
- [ ] Mensaje de límite alcanzado
- [ ] Oferta de **upgrade** a plan Pro (no error críptico)

### Resultado

| ☐ Aprobado | ☐ Falló | ☐ N/A | Notas: |

---

## Checklist de sesión — Quizzes y práctica

| ID | Prueba | Android | Web |
|----|--------|:-------:|:---:|
| M-QUIZ-01 | Crear quiz | ☐ | ☐ |
| M-QUIZ-02 | Añadir preguntas | ☐ | ☐ |
| M-QUIZ-03 | Publicar | ☐ | ☐ |
| M-PRAC-01 | Práctica completa | ☐ | ☐ |
| M-PRAC-02 | Reanudar sesión | ☐ | ☐ |
| M-PRAC-03 | Historial | ☐ | ☐ |
| M-QUIZ-04 | Import Excel | ☐ | ☐ |
| M-QUIZ-05 | Límite Free | ☐ | ☐ |

**Siguiente:** [03_PAGOS_Y_SUSCRIPCIONES.md](03_PAGOS_Y_SUSCRIPCIONES.md)
