# App Store — suscripciones y revisión (Guideline 3.1.2)

Checklist para cumplir el requisito de Apple sobre **título, duración, precio** y **enlaces funcionales a Privacidad y Términos (EULA)** en la pantalla de compra, además de los metadatos en App Store Connect.

## En la app (Flutter)

Las pantallas de paywall incluyen:

| Pantalla | Ruta / acceso | Qué muestra |
|----------|---------------|-------------|
| Mejorar plan | `UpgradePlanPage` | Nombre del plan, ciclo mensual/anual, precio, CTA de compra, enlaces **Política de privacidad** y **Términos de uso (EULA)** (iOS) |
| Plan docente | `TeacherUpgradePage` | Igual, bajo el aviso de cancelación |

URLs (definidas en `legal_urls.dart`):

- Privacidad: `https://craftquestai.com/privacidad`
- Términos / EULA: `https://craftquestai.com/terminos`

Widget reutilizado: `SubscriptionPaywallLegalLinks` en `lib/core/compliance/legal_links.dart`.

## App Store Connect — metadatos

Completar **antes** de enviar a revisión:

### 1. Privacy Policy URL

App Store Connect → **App Information** → **Privacy Policy URL**:

```
https://craftquestai.com/privacidad
```

### 2. Terms of Use (EULA)

Elegir **una** de estas opciones:

**Opción A — Descripción de la app** (todas las localizaciones, p. ej. inglés y español):

Añadir al final de la descripción:

```
Terms of Use (EULA): https://craftquestai.com/terminos
```

**Opción B — EULA personalizado**

App Store Connect → **App Information** → **License Agreement** → pegar el texto del EULA o enlace a `https://craftquestai.com/terminos`.

**Opción C — EULA estándar de Apple** (solo si no usáis términos propios):

```
https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

CraftQuest usa términos propios → preferir **Opción A** o **B** con `https://craftquestai.com/terminos`.

### 3. Notes for App Review

En el envío del build, campo **Notes** (App Review Information):

```
Subscription paywall (Upgrade Plan and Teacher Upgrade) shows subscription title, billing period (monthly/annual), price, and tappable Privacy Policy and Terms of Use (EULA) links before purchase. Privacy: https://craftquestai.com/privacidad — Terms (EULA): https://craftquestai.com/terminos
```

Versión en español (opcional):

```
El paywall de suscripción (Mejorar plan y Plan docente) muestra título, periodo (mensual/anual), precio y enlaces táctiles a Política de privacidad y Términos de uso (EULA) antes de comprar.
```

## Verificación manual (iOS)

1. Abrir **Mejorar plan** → confirmar nombre, ciclo, precio y que los dos enlaces abren el navegador.
2. Abrir **Plan docente** (Upgrade docente) → mismo chequeo bajo el CTA.
3. En App Store Connect, confirmar Privacy Policy URL y EULA en descripción o License Agreement.

## Referencias

- [App Store Review Guideline 3.1.2 — Subscriptions](https://developer.apple.com/app-store/review/guidelines/#subscriptions)
- Configuración IAP: [MOBILE_STORE_SUBSCRIPTIONS.md](./MOBILE_STORE_SUBSCRIPTIONS.md)
