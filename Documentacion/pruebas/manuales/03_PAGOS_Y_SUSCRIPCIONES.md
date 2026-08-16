# Pruebas manuales — Pagos y suscripciones

**Prioridad general:** P0 (crítico para negocio)  
**Tiempo total:** 90–120 min (incluye webhooks)

---

## Parte A — Compras en la app

## M-PAY-01 — Ver plan actual (Free)

**Tiempo:** ~3 min · **Cuenta:** Free verificada

### Pasos

1. Inicia sesión con cuenta Free.
2. Ve a **Perfil**.
3. Revisa sección de **plan** / suscripción.

### Deberías ver
- [ ] Plan **Free** visible
- [ ] Opción **Mejorar plan** / Upgrade accesible

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-PAY-02 — Comprar plan Pro en Android (Google Play)

**Tiempo:** ~15 min · **Plataforma:** Android  
**Requisitos:** Cuenta tester en Play Console + licencia de prueba

### Antes de empezar
- [ ] App instalada desde **Internal testing** o producción
- [ ] Tu cuenta Google está en **License testers** de Play Console
- [ ] Producto `craftquest_pro_monthly` (o anual) activo

### Pasos

1. Inicia sesión en la app.
2. Ve a **Perfil** → **Mejorar plan** (o Home → upgrade).
3. Selecciona plan **Pro** (mensual o anual).
4. Confirma compra en el **diálogo de Google Play** (sandbox: no se cobra real).
5. Espera a que la app procese (pantalla de carga o retorno automático).
6. Ve a **Perfil** de nuevo.

### Deberías ver
- [ ] Plan cambió a **Pro**
- [ ] Límites aumentados (más quizzes, más créditos IA en Perfil)
- [ ] Sin error persistente en pantalla

### Si falla
- Revisa Logcat / Azure logs: `verify-purchase`
- En Play Console → **Pedidos** debe aparecer la compra de prueba

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-PAY-03 — Comprar plan Pro en Web (PayPal)

**Tiempo:** ~15 min · **Plataforma:** Web (Chrome)

### Antes de empezar
- [ ] Cuenta **PayPal Sandbox** comprador configurada
- [ ] App web apunta a API con PayPal sandbox o prod según entorno

### Pasos

1. Abre CraftQuest en **navegador** (web).
2. Inicia sesión con cuenta Free de prueba.
3. Ve a **Mejorar plan** → elige **Pro**.
4. Se abre **PayPal** → inicia sesión sandbox → aprueba pago.
5. PayPal redirige a **`paypal_return_page`** de CraftQuest.
6. Espera confirmación en la app.
7. Revisa **Perfil**.

### Deberías ver
- [ ] Retorno exitoso desde PayPal
- [ ] Plan **Pro** activo en Perfil

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-PAY-04 — Cancelar renovación automática

**Tiempo:** ~10 min · **Cuenta:** Pro activa (M-PAY-02 o M-PAY-03)

### Pasos

1. En **Perfil** o sección de suscripción, busca **Cancelar renovación** / manage subscription.
2. Sigue el flujo de cancelación (puede abrir Play Store en Android o confirmar en app).
3. Confirma cancelación.

### Deberías ver
- [ ] Mensaje: acceso hasta fin de periodo / cancel at period end
- [ ] Plan sigue **Pro** hasta la fecha de expiración (no baja inmediato)

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-PAY-05 — Comprar créditos IA

**Tiempo:** ~10 min

### Pasos

1. Ve a sección **Créditos IA** / AI credits (Home o Perfil).
2. Elige un **pack** de créditos.
3. Completa pago (IAP en Android o PayPal en Web).
4. Revisa contador de créditos en Perfil.

### Deberías ver
- [ ] Créditos incrementados tras compra

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## Parte B — Webhooks Google Play (staging/prod)

> Ejecuta en entorno con **Pub/Sub real** conectado a `/api/webhooks/google-play`.  
> Migración SQL `PaymentIssuePending` debe estar aplicada.

---

## M-WH-01 — Notificación de prueba desde Play Console

**Tiempo:** ~10 min

### Pasos

1. Abre **Google Play Console** → tu app → **Monetización** → **Suscripciones**.
2. Busca **Real-time developer notifications** / enviar **test notification**.
3. Espera 1–2 minutos.
4. En **Google Cloud Console** → Pub/Sub → suscripción → verifica que no hay mensajes **pendientes** sin ack.
5. (Opcional) Azure **Log stream**: busca log de test notification, respuesta **200**.

### Deberías ver
- [ ] Mensaje confirmado (no encolado indefinidamente)
- [ ] API responde 200 OK

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-WH-02 — Renovación (tipo 2) actualiza fecha de expiración

**Tiempo:** ~20 min · **Requisito:** suscripción activa de prueba

### Pasos

1. Anota en SQL o Perfil la fecha **EndsAt** / expiración actual del usuario de prueba.
2. En Play Console, usa **Test renewal** o espera renovación sandbox.
3. Espera webhook (1–5 min).
4. Consulta SQL:
   ```sql
   SELECT EndsAt, LastPaymentAt, PaymentIssuePending, Status
   FROM billing.UserSubscriptions
   WHERE UserId = '<tu-user-id>';
   ```

### Deberías ver
- [ ] `EndsAt` **actualizada** (fecha futura de Google, no cálculo viejo)
- [ ] `PaymentIssuePending = 0`
- [ ] `LastPaymentAt` reciente

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-WH-03 — Cancelación (tipo 3) mantiene acceso hasta fin de periodo

**Tiempo:** ~15 min

### Pasos

1. Cancela suscripción desde **Play Store** (cuenta de prueba) o simula evento tipo 3.
2. Espera webhook.
3. Revisa SQL: `AutoRenewEnabled`, `CancelAtPeriodEnd`, `EndsAt`.

### Deberías ver
- [ ] Usuario **sigue con acceso Pro** hasta `EndsAt`
- [ ] Auto-renovación desactivada

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-WH-04 — Grace period (tipo 6) bloquea IA

**Tiempo:** ~20 min

### Pasos

1. Simula evento **IN_GRACE_PERIOD** (tipo 6) desde Play Console test o sandbox.
2. Espera webhook.
3. En SQL verifica `PaymentIssuePending = 1`.
4. En la **app**, intenta **generar preguntas con IA** (subir PDF y generar).

### Deberías ver
- [ ] Notificación in-app o email de **problema de pago** (según preferencias)
- [ ] Generación IA **bloqueada** con mensaje claro (no error genérico 500)
- [ ] Práctica normal de quizzes **sigue funcionando** (solo IA bloqueada)

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-WH-05 — Revocación / reembolso (tipo 12) corta acceso inmediato

**Tiempo:** ~15 min · **Cuidado:** usa cuenta de prueba dedicada

### Pasos

1. Con suscripción Pro activa, simula **REVOKED** (tipo 12) o reembolso en Play Console.
2. Espera webhook.
3. Revisa SQL: plan debe bajar a **free**.
4. Abre la app (cierra y abre) → **Perfil**.

### Deberías ver
- [ ] Acceso Pro **revocado de inmediato** (no espera a EndsAt)
- [ ] Plan **Free** en UI

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## Checklist — Pagos y webhooks

| ID | Prueba | Resultado |
|----|--------|-----------|
| M-PAY-01 | Plan Free visible | ☐ |
| M-PAY-02 | Compra Pro Android | ☐ |
| M-PAY-03 | Compra Pro Web/PayPal | ☐ |
| M-PAY-04 | Cancelar renovación | ☐ |
| M-PAY-05 | Créditos IA | ☐ |
| M-WH-01 | Test notification Pub/Sub | ☐ |
| M-WH-02 | Renovación tipo 2 | ☐ |
| M-WH-03 | Cancelación tipo 3 | ☐ |
| M-WH-04 | Grace period tipo 6 | ☐ |
| M-WH-05 | Revocación tipo 12 | ☐ |

**Siguiente:** [04_GENERACION_IA.md](04_GENERACION_IA.md)
