# Guía de pruebas manuales — Cómo ejecutar

Esta carpeta contiene **instrucciones paso a paso** para probar CraftQuest a mano. Cada documento es independiente: abre uno, sigue los pasos en orden y marca el resultado al final de cada prueba.

Los documentos técnicos de referencia (API, tests automatizados) están en la carpeta padre: [`Documentacion/pruebas/`](../).

---

## Índice de guías manuales

| Orden | Documento | Qué pruebas | Prioridad |
|-------|-----------|-------------|-----------|
| 1 | [01_REGISTRO_Y_LOGIN.md](01_REGISTRO_Y_LOGIN.md) | Registro, verificación, login, OAuth, contraseña | P0 |
| 2 | [02_QUIZZES_Y_PRACTICA.md](02_QUIZZES_Y_PRACTICA.md) | Crear quiz, preguntas, publicar, practicar | P0 / P1 |
| 3 | [03_PAGOS_Y_SUSCRIPCIONES.md](03_PAGOS_Y_SUSCRIPCIONES.md) | Comprar plan, PayPal, Google Play, webhooks | P0 |
| 4 | [04_GENERACION_IA.md](04_GENERACION_IA.md) | Subir PDF, generar preguntas con IA | P1 |
| 5 | [05_DOCENTE_Y_ESTUDIANTE.md](05_DOCENTE_Y_ESTUDIANTE.md) | Clases, tareas, revisión de intentos | P1 |
| 6 | [06_PREP_PLUS.md](06_PREP_PLUS.md) | Catálogo, preview, compra simulacros | P1 |
| 7 | [07_COMPARTIR_Y_GUEST.md](07_COMPARTIR_Y_GUEST.md) | Códigos de share, modo invitado | P1 |
| 8 | [08_PRACTICA_OFFLINE.md](08_PRACTICA_OFFLINE.md) | Descargar, practicar sin red, sincronizar | P1 |
| 9 | [09_NOTIFICACIONES_Y_PERFIL.md](09_NOTIFICACIONES_Y_PERFIL.md) | Push, bandeja, perfil, idioma | P1 / P2 |
| 10 | [10_FLUJOS_COMPLETOS.md](10_FLUJOS_COMPLETOS.md) | Recorridos E2E de punta a punta | P0 |

---

## Antes de empezar (una sola vez)

### 1. Elige el entorno

| Entorno | API | Cuándo usarlo |
|---------|-----|---------------|
| **Producción** | `https://api.craftquestai.com` | Pruebas finales antes de release |
| **Staging / Azure** | URL de tu App Service | Pruebas de webhooks y pagos reales |
| **Local** | `http://localhost:5000` o `10.0.2.2:5000` (Android emulador) | Desarrollo |

### 2. Prepara dispositivos

Mínimo recomendado para sign-off:

- [ ] **Android** (teléfono o emulador) con app instalada desde Play Internal Testing o build local
- [ ] **Web** en Chrome: `https://app.craftquestai.com` o build local
- [ ] (Opcional) iOS con cuenta sandbox de App Store

### 3. Cuentas de prueba

Crea y anota en un bloc de notas:

| Rol | Email sugerido | Para qué |
|-----|----------------|----------|
| Usuario nuevo | `qa+nuevo@tudominio.com` | Registro desde cero |
| Usuario Free | `qa+free@tudominio.com` | Límites del plan gratis |
| Usuario Pro | `qa+pro@tudominio.com` | Tras comprar suscripción |
| Docente | `qa+teacher@tudominio.com` | Plan Teacher + clases |
| Estudiante | `qa+student@tudominio.com` | Miembro de clase del docente |

**Contraseña de prueba sugerida:** una que cumpla mínimo 8 caracteres (ej. `TestPass123!`).

### 4. Herramientas útiles

- **Email:** acceso al buzón de las cuentas QA (para links de verificación)
- **Postman** (opcional): solo si pruebas API directamente
- **Google Play Console:** licencias de prueba + envío de notificaciones RTDN
- **Azure Portal:** Log Stream para ver webhooks
- **SQL** (opcional): verificar suscripciones en `billing.UserSubscriptions`

### 5. Migración SQL (solo si pruebas webhooks Google Play)

Ejecuta una vez en la base de datos de staging/prod:

```
Documentacion/AlterUserSubscriptions_PaymentIssuePending.sql
```

---

## Cómo registrar resultados

Al final de **cada prueba** hay una tabla como esta:

| Resultado | Marca |
|-----------|-------|
| Aprobado | ☐ |
| Falló | ☐ |
| No aplica | ☐ |

Anota también:
- **Fecha**
- **Dispositivo** (ej. Pixel 8 / Chrome Windows)
- **Bug** (si falló): qué pasó vs qué esperabas

Puedes copiar la plantilla a Excel/Notion con columnas: `ID | Documento | Resultado | Fecha | Tester | Notas`.

---

## Orden recomendado (4 sesiones)

### Sesión 1 — Crítico (P0) ~2–3 h
1. [01_REGISTRO_Y_LOGIN.md](01_REGISTRO_Y_LOGIN.md) — pruebas M-AUTH-01 a M-AUTH-05
2. [03_PAGOS_Y_SUSCRIPCIONES.md](03_PAGOS_Y_SUSCRIPCIONES.md) — pruebas M-PAY-01 a M-PAY-04
3. [10_FLUJOS_COMPLETOS.md](10_FLUJOS_COMPLETOS.md) — flujo E2E-001

### Sesión 2 — Producto core (P1) ~3 h
1. [02_QUIZZES_Y_PRACTICA.md](02_QUIZZES_Y_PRACTICA.md)
2. [04_GENERACION_IA.md](04_GENERACION_IA.md)
3. [10_FLUJOS_COMPLETOS.md](10_FLUJOS_COMPLETOS.md) — E2E-002

### Sesión 3 — Educación y Prep+ (P1) ~2 h
1. [05_DOCENTE_Y_ESTUDIANTE.md](05_DOCENTE_Y_ESTUDIANTE.md)
2. [06_PREP_PLUS.md](06_PREP_PLUS.md)
3. [07_COMPARTIR_Y_GUEST.md](07_COMPARTIR_Y_GUEST.md)

### Sesión 4 — Offline y extras (P1/P2) ~2 h
1. [08_PRACTICA_OFFLINE.md](08_PRACTICA_OFFLINE.md)
2. [09_NOTIFICACIONES_Y_PERFIL.md](09_NOTIFICACIONES_Y_PERFIL.md)
3. [10_FLUJOS_COMPLETOS.md](10_FLUJOS_COMPLETOS.md) — resto de flujos

---

## Tests automatizados (opcional, antes de manual)

Si quieres validar lo básico del código antes de las pruebas manuales:

```powershell
dotnet test tests/CraftQuest.UnitTests
dotnet test tests/CraftQuest.IntegrationTests
cd mobile/craftquest_app
flutter test
```

Todos deben estar en verde antes de la sesión P0 de pagos/webhooks.
