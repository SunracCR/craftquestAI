# Pruebas manuales — Generación con IA

**Tiempo total:** 45–60 min  
**Cuenta:** Pro (recomendado) con **créditos IA** disponibles  
**Requisito backend:** `Ai:GeminiApiKey` configurada en el entorno

---

## M-AI-01 — Subir material PDF

**Prioridad:** P1 · **Tiempo:** ~10 min

### Antes de empezar
- [ ] PDF de prueba (< 20 MB, ~5–20 páginas, texto seleccionable)
- [ ] Créditos IA > 0 (ver Perfil)

### Pasos

1. Inicia sesión.
2. En **Home**, entra al hub de **Generación IA** / AI.
3. Toca **Subir material** / upload.
4. Selecciona tu PDF de prueba.
5. Espera a que termine la **subida**.
6. Permanece en pantalla hasta que el estado pase de "procesando" a **listo** (puede tardar 1–3 min).

### Deberías ver
- [ ] Barra de progreso o indicador de procesamiento
- [ ] Material aparece en **biblioteca** de materiales
- [ ] Texto extraído disponible para revisión (si la app lo muestra)

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-AI-02 — Revisar outline y parámetros

**Tiempo:** ~10 min

### Pasos

1. Abre el material subido en M-AI-01.
2. Revisa pantalla de **outline** / esquema (si aparece).
3. Continúa a **parámetros de generación**:
   - Cantidad de preguntas: **10**
   - Idioma: **Español**
   - Tipos: single + multiple choice
4. Revisa **estimación de créditos** si la app la muestra.
5. Confirma para **iniciar generación**.

### Deberías ver
- [ ] Estimación de créditos coherente
- [ ] Generación iniciada → pantalla de **progreso**

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-AI-03 — Esperar generación y obtener quiz borrador

**Tiempo:** ~15–25 min (depende del documento)

### Pasos

1. En pantalla de **progreso**, espera (no cierres la app).
2. La app hace polling; puede tardar varios minutos.
3. Cuando termine, deberías poder **importar** o abrir el **quiz borrador**.
4. Abre el quiz generado.
5. Revisa que tenga ~10 preguntas con opciones.

### Deberías ver
- [ ] Job completado (no stuck en "processing" > 15 min)
- [ ] Preguntas en español, formato válido
- [ ] Créditos IA **descontados** en Perfil

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-AI-04 — Publicar y practicar quiz generado

**Tiempo:** ~10 min

### Pasos

1. Desde el quiz generado, **publica** (igual que M-QUIZ-03).
2. **Practica** el quiz completo.
3. Termina sesión y revisa resultados.

### Deberías ver
- [ ] Práctica funciona igual que quiz manual
- [ ] Puntuación calculada correctamente

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-AI-05 — Sin créditos IA (cuenta Free agotada)

**Tiempo:** ~5 min · **Cuenta:** Free sin créditos

### Pasos

1. Con cuenta sin créditos, intenta iniciar una generación.

### Deberías ver
- [ ] Mensaje claro: sin créditos / upgrade requerido
- [ ] No error 500 genérico

### Resultado

| ☐ Aprobado | ☐ Falló | ☐ N/A | Notas: |

---

## M-AI-06 — Bloqueo por problema de pago (PaymentIssuePending)

**Tiempo:** ~5 min · **Requisito:** completar M-WH-04 antes

### Pasos

1. Con cuenta en grace period (`PaymentIssuePending`), intenta generar IA.

### Deberías ver
- [ ] Mensaje de **problema de pago pendiente**
- [ ] Generación no inicia

### Resultado

| ☐ Aprobado | ☐ Falló | ☐ N/A | Notas: |

---

## Checklist — Generación IA

| ID | Prueba | Resultado |
|----|--------|-----------|
| M-AI-01 | Subir PDF | ☐ |
| M-AI-02 | Parámetros | ☐ |
| M-AI-03 | Generación completa | ☐ |
| M-AI-04 | Publicar y practicar | ☐ |
| M-AI-05 | Sin créditos | ☐ |
| M-AI-06 | Bloqueo pago pendiente | ☐ |

**Siguiente:** [05_DOCENTE_Y_ESTUDIANTE.md](05_DOCENTE_Y_ESTUDIANTE.md)
