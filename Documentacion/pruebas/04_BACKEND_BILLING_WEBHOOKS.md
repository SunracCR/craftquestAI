# 04 — Backend: Billing, Payments y Webhooks

Controladores: `BillingController`, `PaymentsController`, `PaymentWebhooksController`.

Background job: `SubscriptionRenewalHostedService` (backup expiración cada 6h).

Migración requerida: [`Documentacion/AlterUserSubscriptions_PaymentIssuePending.sql`](../AlterUserSubscriptions_PaymentIssuePending.sql)

Tests automatizados existentes:
- `Billing/BillingServiceCreditTests.cs`, `BillingServicePurchasesTests.cs`, `BillingServiceQuizModificationTests.cs`
- `Billing/BillingServiceGooglePlayWebhookTests.cs` (revoke, renew, PaymentIssuePending gate)
- `Billing/AiCreditPackPaymentTests.cs`, `AiCreditPeriodCalculatorTests.cs`
- `Payments/PaymentServiceMockTests.cs` (PayPal mock, IAP mock)
- `Payments/GooglePlayPubSubWebhookTests.cs` (tipos 2/3/6/12, envelope inválido)

Tests sugeridos:
- `tests/CraftQuest.UnitTests/Payments/PaymentWebhookSecurityServiceTests.cs`
- `tests/CraftQuest.UnitTests/Payments/AppleStoreWebhookTests.cs`
- `tests/CraftQuest.IntegrationTests/Billing/BillingEndpointsIntegrationTests.cs`

---

## Billing — Estado de suscripción

### BILL-001 — GET /api/billing/me

| Prioridad | P0 |
| **Endpoint** | `GET /api/billing/me` |
| **Resultado esperado** | planId, status, endsAt, autoRenew, aiCredits, PaymentIssuePending (si expuesto) |

### BILL-002 — Historial de compras

| **Endpoint** | `GET /api/billing/purchases` |
| **Automatizado** | Sí → `BillingServicePurchasesTests` |

### BILL-003 — Cancelar suscripción

| **Endpoint** | `POST /api/billing/cancel` o `/cancel-auto-renew` |
| **Resultado esperado** | AutoRenew=false; CancelAtPeriodEnd=true; acceso hasta EndsAt |

### BILL-004 — Reanudar auto-renovación

| **Endpoint** | `POST /api/billing/resume-auto-renew` |
| **Resultado esperado** | AutoRenew=true |

### BILL-005 — Suscripción por expirar

| **Endpoint** | `GET /api/billing/expiring?withinDays=7` |

---

## Payments — Planes y PayPal

### BILL-010 — Listar planes

| **Endpoint** | `GET /api/billing/plans` |
| **Resultado esperado** | Planes pro, teacher con precios y product IDs |

### BILL-011 — Crear orden PayPal (suscripción one-time)

| **Endpoint** | `POST /api/billing/paypal/create-order` |
| **Automatizado** | Parcial → `PaymentServiceMockTests` (mock mode) |
| **Sandbox** | Cuenta comprador PayPal sandbox |

### BILL-012 — Capturar orden PayPal

| **Endpoint** | `POST /api/billing/paypal/capture-order` |
| **Resultado esperado** | Plan activado; registro en Purchases |

### BILL-013 — Crear suscripción PayPal recurrente

| **Endpoints** | `create-subscription` → `activate-subscription` |
| **Automatizado** | Parcial → `PaymentServiceMockTests` |

---

## Payments — Mobile IAP

### BILL-020 — Verificar compra suscripción móvil

| Prioridad | P0 |
| **Endpoint** | `POST /api/billing/mobile/verify-purchase` |
| **Body** | `{ platform, productId, purchaseToken/receipt }` |
| **Mock** | `UseMockPayments=true` → acepta token mock |
| **Real** | Token de licencia de prueba Google Play / Sandbox Apple |

### BILL-021 — Idempotencia verify-purchase

| **Automatizado** | Parcial → `PaymentServiceMockTests` |
| **Pasos** | Enviar mismo purchaseToken dos veces |
| **Resultado esperado** | Segunda llamada no duplica suscripción |

---

## Créditos IA

### BILL-030 — Listar packs

| **Endpoint** | `GET /api/billing/ai-credit-packs` |

### BILL-031 — Comprar pack PayPal

| **Endpoints** | `create-ai-credit-order` → `capture-ai-credit-order` |
| **Automatizado** | Sí → `AiCreditPackPaymentTests` |

### BILL-032 — Comprar pack móvil

| **Endpoint** | `POST /api/billing/mobile/verify-ai-credit-purchase` |

### BILL-033 — Reset mensual créditos free

| **Automatizado** | Sí → `AiCreditPeriodCalculatorTests`, `BillingServiceCreditTests` |

---

## Webhook PayPal

### WH-PAY-001 — POST /api/webhooks/paypal

| Prioridad | P0 |
| **Precondiciones** | `Payments:PayPal:WebhookId`; firma válida |
| **Pasos** | Simular evento `BILLING.SUBSCRIPTION.*` o `PAYMENT.CAPTURE.COMPLETED` |
| **Resultado esperado** | 200 OK; evento en `ProviderWebhookEvents`; suscripción actualizada |
| **Automatizado** | No → `PayPalWebhookIntegrationTests.cs` |

### WH-PAY-002 — Firma inválida

| **Resultado esperado** | 401/403; evento no procesado |

---

## Webhook Google Play (Pub/Sub)

Endpoint: `POST /api/webhooks/google-play`  
Formato: envelope Pub/Sub `{ "message": { "data": "<base64>" }, "subscription": "..." }`  
Inner payload: `subscriptionNotification` o `testNotification`.

Config producción:
- `Payments:Webhooks:GooglePubSubAudience` = URL exacta del endpoint
- JWT Bearer validado por `GooglePubSubJwtValidator`

### WH-GP-000 — Notificación de prueba (testNotification)

| Prioridad | P0 |
| **Pasos** | Enviar desde Play Console "Send test notification" |
| **Resultado esperado** | **200 OK** inmediato; mensaje ack en Pub/Sub; log "test notification" |
| **Automatizado** | Parcial → manejo en `GooglePlayPubSubWebhookTests` |

### WH-GP-001 — Tipo 4 PURCHASED (compra nueva)

| **notificationType** | 4 |
| **Resultado esperado** | Suscripción activa; ExpiryTime de Google API; PaymentIssuePending=false |

### WH-GP-002 — Tipo 2 RENEWED (renovación)

| **notificationType** | 2 |
| **Automatizado** | Sí → `GooglePlayPubSubWebhookTests`, `BillingServiceGooglePlayWebhookTests` |
| **Verificar BD** | `EndsAt` = ExpiryTime de Google (no cálculo local); `LastPaymentAt` actualizado |
| **Verificar** | Llama `GooglePlaySubscriptionVerifier.GetSubscriptionAsync` |

### WH-GP-003 — Tipos 1 RECOVERED, 7 RESTARTED

| **notificationType** | 1, 7 |
| **Resultado esperado** | Igual que renovación; PaymentIssuePending=false |

### WH-GP-004 — Tipo 3 CANCELED

| **notificationType** | 3 |
| **Automatizado** | Sí → `GooglePlayPubSubWebhookTests` |
| **Resultado esperado** | AutoRenewEnabled=false; CancelAtPeriodEnd=true; **acceso hasta EndsAt** |

### WH-GP-005 — Tipo 13 EXPIRED

| **notificationType** | 13 |
| **Resultado esperado** | CancelAtPeriodEnd; downgrade al expirar periodo |

### WH-GP-006 — Tipo 12 REVOKED (reembolso)

| Prioridad | P0 |
| **notificationType** | 12 |
| **Automatizado** | Sí → `GooglePlayPubSubWebhookTests`, `BillingServiceGooglePlayWebhookTests` |
| **Resultado esperado** | **`RevokeSubscriptionImmediatelyAsync`** → downgrade a free **inmediato** |
| **Verificar BD** | status=cancelled/free; EndsAt=now |

### WH-GP-007 — Tipo 5 ON_HOLD

| Prioridad | P0 |
| **notificationType** | 5 |
| **Resultado esperado** | `PaymentIssuePending=true`; notificación `payment_issue_pending` enviada |
| **Verificar** | Push/email según preferencias |

### WH-GP-008 — Tipo 6 IN_GRACE_PERIOD

| Prioridad | P0 |
| **notificationType** | 6 |
| **Automatizado** | Sí → `GooglePlayPubSubWebhookTests` |
| **Resultado esperado** | Igual que ON_HOLD; PaymentIssuePending=true |

### WH-GP-009 — PaymentIssuePending bloquea IA

| **Pasos** | Tras tipo 5/6, llamar endpoint que use `EnsureHasAiCreditsAsync` |
| **Resultado esperado** | 402 `PAYMENT_ISSUE_PENDING` |
| **Automatizado** | Sí → `BillingServiceGooglePlayWebhookTests` |

### WH-GP-010 — Renovación limpia PaymentIssuePending

| **Pasos** | Tipo 6 → luego tipo 2 |
| **Resultado esperado** | PaymentIssuePending=false tras renovación exitosa |

### WH-GP-011 — Envelope inválido / body vacío

| **Automatizado** | Sí → `GooglePlayPubSubWebhookTests` |
| **Resultado esperado** | 200 OK (body vacío) o log + 200 sin crash; Pub/Sub no reintenta infinitamente por 500 |

### WH-GP-012 — eventTimeMillis como string

| **Automatizado** | Sí → fix en `MobileStoreWebhookProcessor.ReadLong` |
| **Resultado esperado** | Parseo correcto; no InvalidOperationException |

### WH-GP-013 — Suscripción sin fila local

| **Automatizado** | Sí → `GooglePlayPubSubWebhookTests` |
| **Resultado esperado** | Evento registrado en `ProviderWebhookEvents`; no crash |

### WH-GP-014 — JWT Pub/Sub inválido

| **Config** | `RequireVerification=true`, audience incorrecto |
| **Resultado esperado** | 401; mensajes encolados en Pub/Sub (revisar logs Azure) |

### WH-GP-015 — Fallback ExpiryTime si Google API falla

| **Pasos** | Simular fallo en `GetSubscriptionAsync` durante tipo 2 |
| **Resultado esperado** | Usa cálculo local de periodo; log warning |

---

## Webhook App Store

### WH-AS-001 — POST /api/webhooks/app-store

| Prioridad | P0 |
| **Formato** | JWS signedPayload |
| **Eventos** | SUBSCRIBED, DID_RENEW, DID_FAIL_TO_RENEW, REFUND, etc. |
| **Automatizado** | No → `AppleStoreWebhookTests.cs` |

### WH-AS-002 — Revocación / refund

| **Resultado esperado** | Revocación inmediata equivalente a tipo 12 Google |

### WH-AS-003 — Grace period / billing retry

| **Resultado esperado** | PaymentIssuePending=true + notificación |

---

## SubscriptionRenewalHostedService

### BILL-040 — Expiración backup sin webhook

| **Tipo** | Manual |
| **Pasos** | Suscripción con EndsAt pasado, sin webhook recibido |
| **Esperar** | Job cada 6h o forzar ejecución |
| **Resultado esperado** | Downgrade a free |

---

## Verificación SQL post-webhook

```sql
SELECT UserId, PlanId, Status, EndsAt, AutoRenewEnabled, CancelAtPeriodEnd,
       PaymentIssuePending, LastPaymentAt, ProviderPurchaseToken
FROM billing.UserSubscriptions
WHERE UserId = @testUserId;

SELECT EventId, Provider, EventType, ProcessedAt, PayloadHash
FROM billing.ProviderWebhookEvents
ORDER BY ProcessedAt DESC;
```

---

## Checklist sign-off Billing

- [ ] PayPal sandbox: compra + captura + webhook
- [ ] Google Play: test notification → 200 OK en Azure
- [ ] Google Play: tipos 2, 3, 6, 12 verificados en staging con BD
- [ ] PaymentIssuePending migración SQL ejecutada en prod
- [ ] App Store sandbox: al menos 1 renovación y 1 cancelación
- [ ] `dotnet test --filter "Billing|Payments|GooglePlay"` en verde
- [ ] Pub/Sub sin mensajes pendientes tras pruebas
