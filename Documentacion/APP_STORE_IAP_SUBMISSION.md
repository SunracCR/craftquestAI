# App Store Connect — enviar IAP a revisión (Guideline 2.1(b))

Rechazo típico: *"the app includes references to plans and credits but the associated In-App Purchase products have not been submitted for review"*.

Los productos **existen** en ASC pero deben estar en estado **Ready to Submit** y **incluidos en la misma versión** que el binario iOS.

## Productos obligatorios (7 IDs)

Fuente: `src/CraftQuest.Api/appsettings.json` → `Payments:PlanProducts` / `Payments:AiCreditPacks`.

### Suscripciones auto-renovables (mismo Subscription Group)

| Product ID | Plan | Ciclo | Pantalla en la app |
|------------|------|-------|-------------------|
| `craftquest_pro_monthly` | Pro | Mensual | Profile → Upgrade plan |
| `craftquest_pro_annual` | Pro | Anual | Profile → Upgrade plan |
| `craftquest_teacher_monthly` | Tutor / Teacher | Mensual | Profile → Teacher upgrade |
| `craftquest_teacher_annual` | Tutor / Teacher | Anual | Profile → Teacher upgrade |

### Consumibles (créditos IA)

| Product ID | Tier | Créditos | Precio USD | Pantalla en la app |
|------------|------|----------|------------|-------------------|
| `craftquest_ai_credits_50` | Starter | 30 (~5 gen) | $4.99 | Home → Buy AI credits |
| `craftquest_ai_credits_120` | Plus | 60 (~10 gen) | $9.99 | Home → Buy AI credits |
| `craftquest_ai_credits_300` | Max | 150 (~25 gen) | $19.99 | Home → Buy AI credits |

### Prep+ (opcional)

Si hay ofertas Prep+ activas con `storeProductId` en iOS (prefijo `craftquest_prep_`), cada SKU también debe estar **Submitted**. Si no hay ofertas live, omitir.

---

## Checklist por producto (ASC)

App Store Connect → **Monetization** → **Subscriptions** o **In-App Purchases**.

Para **cada uno** de los 7 productos:

- [ ] **Reference Name** y **Product ID** coinciden con la tabla anterior
- [ ] **Display Name** y **Description** (inglés mínimo; recomendable ES/PT)
- [ ] **Precio** configurado (tier equivalente a USD en la app)
- [ ] **Review Screenshot** subida (Apple lo exige para submit)
- [ ] Estado: **Ready to Submit** (no Missing Metadata)

### Qué screenshot usar

| Tipo | Captura recomendada |
|------|---------------------|
| Suscripciones Pro/Teacher | Pantalla **Upgrade plan** o **Teacher upgrade**: nombre del plan, Monthly/Annual, precio, botón Buy in store, enlaces Privacy + EULA |
| Créditos IA | Pantalla **Buy AI credits**: Starter / Plus / Max con precios y botones Buy |

Usar capturas del **iPad** si la revisión fue en iPad (como en 1.1.0 build 62).

---

## Enviar versión + IAP juntos

1. Subir **nuevo binario** iOS (build incrementado, p. ej. 63+).
2. App Store → versión → seleccionar el build.
3. En la misma versión, sección **In-App Purchases and Subscriptions** → añadir los **7 productos**.
4. Completar **App Review Information** (Notes, demo account si aplica).
5. **Submit for Review** (app + IAP en el mismo envío).

Si los IAP no aparecen para añadir, revisar que cada uno esté **Ready to Submit** y que el acuerdo fiscal/bancario de ASC esté activo.

---

## Verificación antes de Submit

- [ ] Los 7 product IDs en ASC = `appsettings.json`
- [ ] Cada producto tiene Review Screenshot
- [ ] Binario nuevo incluye paywall con enlaces legales (3.1.2)
- [ ] iOS ya no exige DOB al abrir (5.1.1(v)) — build con `AgeCollectionPolicy`
- [ ] Respuesta en Resolution Center preparada → [APP_STORE_RESOLUTION_REPLY.md](./APP_STORE_RESOLUTION_REPLY.md)

## Referencias

- [Submit an In-App Purchase](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/submit-an-in-app-purchase-for-review)
- [MOBILE_STORE_SUBSCRIPTIONS.md](./MOBILE_STORE_SUBSCRIPTIONS.md)
- [APP_STORE_SUBSCRIPTION_REVIEW.md](./APP_STORE_SUBSCRIPTION_REVIEW.md)
