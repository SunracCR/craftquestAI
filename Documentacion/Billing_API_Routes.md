# Rutas de facturación y pagos (`api/billing`)

Dos controladores comparten el prefijo **`/api/billing`** por diseño histórico. ASP.NET Core los distingue por la ruta completa del action.

## `BillingController` — suscripción y uso

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/billing/me` | Plan activo, uso, créditos, entitlements |
| GET | `/api/billing/purchases` | Historial de compras del usuario |
| POST | `/api/billing/cancel` | Cancelar suscripción (vuelve a plan free) |
| GET | `/api/billing/expiring` | ¿La suscripción caduca pronto? |

## `PaymentsController` — cobro y tiendas

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/billing/plans` | Planes mejorables (público si no hay JWT) |
| POST | `/api/billing/paypal/create-order` | Crear orden PayPal (plan Pro/Teacher) |
| POST | `/api/billing/paypal/capture-order` | Capturar pago PayPal |
| POST | `/api/billing/mobile/verify-purchase` | Verificar compra Google Play / App Store |
| GET | `/api/billing/ai-credit-packs` | Paquetes de créditos IA (solo Pro/Teacher) |
| POST | `/api/billing/paypal/create-ai-credit-order` | Orden PayPal one-shot para paquete IA |
| POST | `/api/billing/paypal/capture-ai-credit-order` | Captura y acredita créditos IA |
| POST | `/api/billing/mobile/verify-ai-credit-purchase` | Verificar compra consumible de créditos IA (mock/IAP) |

## Preparación+ (otro prefijo)

Los pagos de catálogo Prep+ usan **`/api/prep/...`** (`PrepController`), no este prefijo.

## Flutter

- `BillingRepository` → `me`, `purchases`, `plans`, PayPal, `verify-purchase`
- Perfil → historial en `GET /api/billing/purchases`
