# Pruebas manuales — Flujos completos (E2E)

Estos recorridos unen varias guías en **una sola sesión**. Úsalos para sign-off antes de un release.

Marca cada flujo completo al terminar todos sus pasos.

---

## E2E-A — Onboarding de usuario nuevo

**Prioridad:** P0 · **Tiempo:** ~25 min · **Plataformas:** Android + Web

### Qué vas a validar
Registro → verificación → login → home con plan Free

### Pasos (en orden)

1. Sigue **[M-AUTH-01](01_REGISTRO_Y_LOGIN.md#m-auth-01--registro-con-email-y-verificación)** completo.
2. Verifica en **Perfil**: plan Free.
3. Navega **Home**: deben verse accesos a Quizzes, Prep+, Perfil.
4. Cierra app y ábrela: sigues logueado.

### Criterio de éxito
- [ ] Usuario nuevo operativo sin errores bloqueantes

### Resultado

| ☐ Aprobado | ☐ Falló | Android | Web |
|------------|---------|:-------:|:---:|
| Fecha: | Tester: | ☐ | ☐ |

---

## E2E-B — Crear quiz y practicar

**Prioridad:** P0 · **Tiempo:** ~40 min

### Pasos (en orden)

1. **[M-QUIZ-01](02_QUIZZES_Y_PRACTICA.md#m-quiz-01--crear-un-quiz-nuevo)** → crear quiz
2. **[M-QUIZ-02](02_QUIZZES_Y_PRACTICA.md#m-quiz-02--añadir-preguntas-single-y-multiple-choice)** → 5+ preguntas
3. **[M-QUIZ-03](02_QUIZZES_Y_PRACTICA.md#m-quiz-03--publicar-el-quiz)** → publicar
4. **[M-PRAC-01](02_QUIZZES_Y_PRACTICA.md#m-prac-01--practicar-online-sesión-completa)** → practicar y terminar
5. **[M-PRAC-03](02_QUIZZES_Y_PRACTICA.md#m-prac-03--ver-historial-de-intentos)** → ver intento en historial

### Criterio de éxito
- [ ] Ciclo completo quiz → práctica → historial sin errores

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## E2E-C — Compra Pro y verificación

**Prioridad:** P0 · **Tiempo:** ~30 min

### Variante Android

1. **[M-PAY-01](03_PAGOS_Y_SUSCRIPCIONES.md#m-pay-01--ver-plan-actual-free)** con cuenta Free
2. **[M-PAY-02](03_PAGOS_Y_SUSCRIPCIONES.md#m-pay-02--comprar-plan-pro-en-android-google-play)**
3. **[M-PAY-04](03_PAGOS_Y_SUSCRIPCIONES.md#m-pay-04--cancelar-renovación-automática)** (opcional al final)

### Variante Web

1. **[M-PAY-03](03_PAGOS_Y_SUSCRIPCIONES.md#m-pay-03--comprar-plan-pro-en-web-paypal)**

### Criterio de éxito
- [ ] Plan Pro activo y límites reflejados en UI

### Resultado

| ☐ Aprobado Android | ☐ Aprobado Web | Notas: |
|--------------------|----------------|--------|

---

## E2E-D — Webhooks Google Play (staging)

**Prioridad:** P0 · **Tiempo:** ~60 min · **Solo staging/prod con Pub/Sub**

### Pasos (en orden)

1. **[M-WH-01](03_PAGOS_Y_SUSCRIPCIONES.md#m-wh-01--notificación-de-prueba-desde-play-console)**
2. Compra suscripción prueba → **[M-PAY-02](03_PAGOS_Y_SUSCRIPCIONES.md#m-pay-02--comprar-plan-pro-en-android-google-play)**
3. **[M-WH-02](03_PAGOS_Y_SUSCRIPCIONES.md#m-wh-02--renovación-tipo-2-actualiza-fecha-de-expiración)**
4. **[M-WH-03](03_PAGOS_Y_SUSCRIPCIONES.md#m-wh-03--cancelación-tipo-3-mantiene-acceso-hasta-fin-de-periodo)**
5. **[M-WH-04](03_PAGOS_Y_SUSCRIPCIONES.md#m-wh-04--grace-period-tipo-6-bloquea-ia)** + **[M-AI-06](04_GENERACION_IA.md#m-ai-06--bloqueo-por-problema-de-pago-paymentissuepending)**
6. **[M-WH-05](03_PAGOS_Y_SUSCRIPCIONES.md#m-wh-05--revocación--reembolso-tipo-12-corta-acceso-inmediato)** (cuenta desechable)

### Criterio de éxito
- [ ] BD y app coherentes en cada paso
- [ ] Pub/Sub sin mensajes atascados

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## E2E-E — Aula virtual (docente + estudiante)

**Prioridad:** P1 · **Tiempo:** ~45 min

### Pasos (en orden)

1. **[M-TCH-01](05_DOCENTE_Y_ESTUDIANTE.md#m-tch-01--crear-una-clase)** → **[M-TCH-02](05_DOCENTE_Y_ESTUDIANTE.md#m-tch-02--invitar-estudiante-a-la-clase)**
2. **[M-TCH-03](05_DOCENTE_Y_ESTUDIANTE.md#m-tch-03--crear-asignación-tarea)**
3. **[M-STU-01](05_DOCENTE_Y_ESTUDIANTE.md#m-stu-01--estudiante-completa-la-asignación)**
4. **[M-TCH-04](05_DOCENTE_Y_ESTUDIANTE.md#m-tch-04--docente-revisa-intento-y-analytics)**

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## E2E-F — Offline en Android

**Prioridad:** P1 · **Tiempo:** ~30 min

### Pasos (en orden)

1. **[M-OFF-01](08_PRACTICA_OFFLINE.md#m-off-01--descargar-quiz-para-offline)**
2. **[M-OFF-02](08_PRACTICA_OFFLINE.md#m-off-02--practicar-sin-conexión)**
3. **[M-OFF-03](08_PRACTICA_OFFLINE.md#m-off-03--sincronizar-al-reconectar)**

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## Sign-off final de release

Completa antes de publicar en producción:

| Flujo | P0/P1 | Resultado | Fecha |
|-------|-------|-----------|-------|
| E2E-A Onboarding | P0 | ☐ | |
| E2E-B Quiz + práctica | P0 | ☐ | |
| E2E-C Compra Pro | P0 | ☐ | |
| E2E-D Webhooks GP | P0 | ☐ | |
| E2E-E Aula | P1 | ☐ | |
| E2E-F Offline | P1 | ☐ | |

**Regla:** Todos los **P0** deben estar aprobados. Los P1 fallidos documentados con plan de fix.

---

## Mapa rápido: guía → documento técnico

| Guía manual | Referencia técnica |
|-------------|-------------------|
| 01 Registro/login | `../01_BACKEND_AUTH.md`, `../08_FLUTTER_AUTH_BILLING.md` |
| 02 Quizzes | `../02_BACKEND_QUIZZES_PRACTICE.md`, `../09_FLUTTER_QUIZZES_PRACTICE_OFFLINE.md` |
| 03 Pagos | `../04_BACKEND_BILLING_WEBHOOKS.md` |
| 04 IA | `../03_BACKEND_AI.md` |
| 05 Docente | `../05_BACKEND_TEACHER_STUDENT.md`, `../10_FLUTTER_TEACHER_STUDENT_GUEST.md` |
| 06 Prep+ | `../06_BACKEND_PREP_PLUS.md` |
| 07 Compartir/Guest | `../07_BACKEND_OTROS.md` |
| 08 Offline | `../09_FLUTTER_QUIZZES_PRACTICE_OFFLINE.md` |
| 09 Notificaciones | `../07_BACKEND_OTROS.md`, `../11_FLUTTER_OTROS.md` |
