# Pruebas manuales — Docente y estudiante

**Tiempo total:** 60–90 min  
**Necesitas:** 2 cuentas (docente + estudiante) y 1 quiz publicado

---

## Preparación (haz esto primero)

### Cuenta docente
- [ ] Usuario con plan **Teacher** activo
- [ ] Al menos **1 quiz publicado** con 5+ preguntas (usa el de [02_QUIZZES_Y_PRACTICA.md](02_QUIZZES_Y_PRACTICA.md))

### Cuenta estudiante
- [ ] Usuario normal (Free o Pro) con email distinto al docente
- [ ] El estudiante **no** debe estar ya en la clase de prueba

---

## M-TCH-01 — Crear una clase

**Cuenta:** Docente · **Tiempo:** ~8 min

### Pasos

1. Inicia sesión como **docente**.
2. En la barra inferior, abre pestaña **Teacher** / Docente.
3. Ve a **Clases** → **Crear clase**.
4. Nombre: `QA Clase Manual 2026`
5. Guarda.
6. Anota el **código de clase** o método de invitación que muestre la app.

### Deberías ver
- [ ] Clase creada en lista
- [ ] Código o enlace para unir estudiantes visible

### Resultado

| ☐ Aprobado | ☐ Falló | Notas / código clase: |

---

## M-TCH-02 — Invitar estudiante a la clase

**Tiempo:** ~10 min

### Pasos

1. Abre la clase creada.
2. **Añadir miembro** → introduce email del **estudiante**.
3. Envía invitación.
4. **Cierra sesión** del docente.
5. Inicia sesión como **estudiante**.
6. Acepta invitación o únete con código (según flujo de la app).
7. Si el docente debe **aprobar**, vuelve a cuenta docente y aprueba al estudiante.

### Deberías ver
- [ ] Estudiante aparece como **miembro activo** en la clase (vista docente)
- [ ] Estudiante ve la clase en **Mis clases**

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-TCH-03 — Crear asignación (tarea)

**Cuenta:** Docente · **Tiempo:** ~10 min

### Pasos

1. Como docente, abre la clase.
2. **Nueva asignación** / Create assignment.
3. Selecciona el **quiz publicado** de prueba.
4. Título: `Tarea QA Semana 1`
5. Fecha límite: dentro de 7 días.
6. Guarda / publica asignación.

### Deberías ver
- [ ] Asignación visible en detalle de clase
- [ ] Estudiante la ve en **Mis asignaciones**

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-STU-01 — Estudiante completa la asignación

**Cuenta:** Estudiante · **Tiempo:** ~15 min

### Pasos

1. Como **estudiante**, ve a **Asignaciones**.
2. Abre **Tarea QA Semana 1**.
3. Toca **Practicar** / iniciar.
4. Completa la sesión (responde todas las preguntas).
5. **Finaliza** y revisa tu puntuación.

### Deberías ver
- [ ] Sesión vinculada a la asignación (no práctica suelta)
- [ ] Resultados visibles para el estudiante

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-TCH-04 — Docente revisa intento y analytics

**Cuenta:** Docente · **Tiempo:** ~15 min

### Pasos

1. Como docente, abre la **asignación**.
2. Revisa **progreso** / completion (debe mostrar estudiante completado).
3. Abre **analytics** de la asignación si existe.
4. Entra al **intento** del estudiante (revisión pregunta por pregunta).

### Deberías ver
- [ ] Completion refleja 1 intento completado
- [ ] Revisión muestra respuestas correctas/incorrectas del estudiante
- [ ] Analytics con datos coherentes (no vacío)

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-TCH-05 — Archivar clase (opcional)

**Tiempo:** ~5 min

### Pasos

1. Como docente, **archiva** la clase de prueba.
2. Verifica que desaparece de activas pero el historial se conserva.

### Deberías ver
- [ ] Clase en sección **archivadas**
- [ ] Intentos anteriores siguen accesibles

### Resultado

| ☐ Aprobado | ☐ Falló | ☐ N/A | Notas: |

---

## Checklist — Docente y estudiante

| ID | Prueba | Docente | Estudiante |
|----|--------|:-------:|:----------:|
| M-TCH-01 | Crear clase | ☐ | — |
| M-TCH-02 | Invitar miembro | ☐ | ☐ |
| M-TCH-03 | Crear asignación | ☐ | — |
| M-STU-01 | Completar tarea | — | ☐ |
| M-TCH-04 | Revisar intento | ☐ | — |
| M-TCH-05 | Archivar clase | ☐ | — |

**Siguiente:** [06_PREP_PLUS.md](06_PREP_PLUS.md)
