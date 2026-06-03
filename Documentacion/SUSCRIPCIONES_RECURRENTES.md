# Suscripciones recurrentes (CraftQuest)

## Resumen

- **PayPal (web)**: suscripciones nativas (`/v1/billing/subscriptions`), no solo cobros únicos.
- **Renovación automática**: activa por defecto al suscribirse (`AutoRenewEnabled = true`).
- **Cancelar**: desactiva la renovación y mantiene el plan hasta `EndsAt` (fin del periodo pagado).
- **La app no programa cobros**: PayPal / tiendas cobran; la API sincroniza vía webhooks y job de respaldo.

## Base de datos

Ejecutar:

`Documentacion/AlterUserSubscriptions_RecurringBilling.sql`

Campos en `billing.UserSubscriptions`:

| Campo | Uso |
|--------|-----|
| `BillingCycle` | `monthly` \| `annual` |
| `AutoRenewEnabled` | Renovación automática ON/OFF |
| `CancelAtPeriodEnd` | Usuario revocó renovación |
| `EndsAt` | Fin del periodo actual |
| `LastPaymentAt` | Último cobro confirmado |
| `ProviderSubscriptionId` | ID en PayPal / store |

Idempotencia de webhooks: `billing.ProviderWebhookEvents`.

## API

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/billing/me` | Incluye `subscription` ampliado |
| POST | `/api/billing/paypal/create-subscription` | Crea suscripción PayPal |
| POST | `/api/billing/paypal/activate-subscription` | Activa tras aprobación |
| POST | `/api/billing/cancel` | Desactiva auto-renew (mantiene acceso) |
| POST | `/api/billing/cancel-auto-renew` | Alias del anterior |
| POST | `/api/webhooks/paypal` | Webhooks PayPal (sin auth) |

Legacy (un solo cobro, sin auto-renew): `create-order` + `capture-order`.

## Configuración PayPal

En `appsettings` → `Payments:PlanProducts`:

```json
"pro": {
  "PayPalMonthlyPlanId": "P-XXXX",
  "PayPalAnnualPlanId": "P-YYYY",
  ...
}
```

Crear planes en [PayPal Subscriptions](https://developer.paypal.com/docs/subscriptions/) (sandbox/producción) y registrar el webhook apuntando a:

`https://<tu-api>/api/webhooks/paypal`

Eventos recomendados: `BILLING.SUBSCRIPTION.ACTIVATED`, `PAYMENT.SALE.COMPLETED`, `BILLING.SUBSCRIPTION.CANCELLED`.

## Flujo mock (desarrollo)

Con `Payments:UseMockPayments: true`:

1. `create-subscription` → `MOCK-SUB-...`
2. `activate-subscription` → plan activo, periodo +1 mes/año, `AutoRenewEnabled = true`
3. `cancel` → acceso hasta `EndsAt`

## Job de respaldo

`SubscriptionRenewalHostedService` (cada 6 h) expira suscripciones con `EndsAt` vencido y sin renovación, bajando a Free.

## Tiendas móviles

Ver guía completa: [MOBILE_STORE_SUBSCRIPTIONS.md](./MOBILE_STORE_SUBSCRIPTIONS.md)

## Flutter

- Compra web: `createPayPalSubscription` + `activatePayPalSubscription`
- Android/iOS: `verifyMobilePurchase` tras compra en tienda
- Cancelar: `cancelSubscription()` devuelve `accessUntil`
- Texto legal: `subscriptionAutoRenewDisclaimer`
