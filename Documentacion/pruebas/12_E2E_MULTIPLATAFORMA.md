# 12 — E2E Multiplataforma: flujos cruzados y matriz

Este documento consolida los **flujos end-to-end** que atraviesan backend + app Flutter, y la **matriz de cobertura por plataforma**.

Referencias: docs 01–11 en `Documentacion/pruebas/`.

---

## Matriz de plataformas

| Capacidad | Android | iOS | Web | Win | macOS | Linux |
|-----------|:-------:|:---:|:---:|:---:|:-----:|:-----:|
| Auth email/OAuth | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Google OAuth | ✓ | ✓ | ✓ | ✓ | — | — |
| Apple OAuth | — | ✓ | ✓* | ✓ | ✓ | — |
| IAP suscripción | ✓ | ✓ | — | — | — | — |
| PayPal checkout | — | — | ✓ | ✓ | ✓ | ✓ |
| Práctica online | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Práctica offline | ✓ | ✓ | **✗** | ✓ | ✓ | ✓ |
| Push FCM | ✓ | ✓ | ✓** | — | — | — |
| Play Age Signals | ✓ | — | — | — | — | — |
| Drag carpetas | — | — | ✓ | ✓ | ✓ | ✓ |
| Deep links join/prep | ✓ | ✓ | ✓ | Parcial | Parcial | — |

\* Apple OAuth en Web requiere Services ID configurado.  
\** FCM web push requiere service worker configurado.

---

## Flujos E2E prioritarios (P0)

### E2E-001 — Onboarding completo

| ID | E2E-001 |
|----|---------|
| **Prioridad** | P0 |
| **Plataformas mínimas** | Android + Web |
| **Actores** | Usuario nuevo |
| **Pasos** | 1. Registro en app. 2. Verificar email (link/código). 3. Login. 4. Ver Home con plan Free. 5. GET `/api/auth/me` coincide con UI |
| **Backend** | AUTH-001 → AUTH-003 → AUTH-005 → AUTH-010 |
| **Flutter** | APP-AUTH-001 → APP-AUTH-003 |
| **Criterio éxito** | Usuario autenticado; shell visible; plan free en perfil |

---

### E2E-002 — Ciclo de vida quiz + práctica

| ID | E2E-002 |
|----|---------|
| **Prioridad** | P0 |
| **Plataformas** | Android, Web |
| **Pasos** | 1. Crear quiz. 2. Añadir 5+ preguntas (single + multiple). 3. Publicar. 4. Practicar online start→finish. 5. Ver intentos y analytics. 6. Export PDF |
| **Backend** | QUIZ-001 → QUIZ-010 → QUIZ-004 → PRAC-001 → PRAC-006 |
| **Flutter** | APP-QUIZ-002 → APP-QUIZ-004 → APP-PRAC-001 → APP-PRAC-005 |
| **Criterio éxito** | Score correcto; intento en historial; analytics reflejan sesión |

---

### E2E-003 — Compra suscripción Pro (multi-canal)

| ID | E2E-003 |
|----|---------|
| **Prioridad** | P0 |
| **Variante A — Android** | IAP Google Play → verify-purchase → webhook tipo 4 → plan Pro en app |
| **Variante B — Web** | PayPal checkout → capture → paypal_return_page → plan Pro |
| **Backend** | BILL-020, BILL-011/012, WH-GP-001 |
| **Flutter** | APP-BILL-002 o APP-BILL-004 |
| **Verificar SQL** | `billing.UserSubscriptions` activa |
| **Criterio éxito** | Límites de plan Pro aplicados (más quizzes, créditos IA) |

---

### E2E-004 — Google Play webhook lifecycle

| ID | E2E-004 |
|----|---------|
| **Prioridad** | P0 |
| **Entorno** | Staging/prod con Pub/Sub real |
| **Pasos** | 1. Compra suscripción (licencia prueba). 2. Play Console: test renew (tipo 2). 3. Simular cancel (tipo 3). 4. Simular grace (tipo 6). 5. Simular revoke (tipo 12) |
| **Backend** | WH-GP-002, WH-GP-004, WH-GP-008, WH-GP-006 |
| **Flutter** | APP-BILL-009 (bloqueo IA tras tipo 6) |
| **Criterio éxito** | BD y UI coherentes en cada paso; Pub/Sub sin mensajes pendientes |

---

### E2E-005 — Generación IA end-to-end

| ID | E2E-005 |
|----|---------|
| **Prioridad** | P1 |
| **Precondiciones** | Usuario Pro con créditos; Gemini API key en staging |
| **Pasos** | 1. Subir PDF. 2. Esperar extracción. 3. Configurar parámetros. 4. Poll job hasta completed. 5. Importar borrador a quiz. 6. Publicar y practicar |
| **Backend** | AI-001 → AI-031 |
| **Flutter** | APP-AI-003 |
| **Criterio éxito** | Quiz con preguntas generadas; créditos descontados |

---

### E2E-006 — Offline download → practice → sync

| ID | E2E-006 |
|----|---------|
| **Prioridad** | P1 |
| **Plataformas** | Android (obligatorio); Desktop opcional |
| **Pasos** | 1. Descargar quiz. 2. Modo avión. 3. Practicar offline. 4. Reconectar. 5. Sync. 6. Ver intento en servidor |
| **Backend** | OFF-001, OFF-002, PRAC offline-sync |
| **Flutter** | APP-OFF-001 → APP-OFF-004 |
| **Criterio éxito** | Intento visible en my-attempts online |

---

### E2E-007 — Teacher classroom completo

| ID | E2E-007 |
|----|---------|
| **Prioridad** | P1 |
| **Actores** | Teacher (cuenta A), Student (cuenta B) |
| **Pasos** | 1. Teacher upgrade. 2. Crear clase. 3. Añadir estudiante. 4. Crear assignment. 5. Student practica. 6. Teacher revisa intento y analytics |
| **Backend** | E2E-TCH-001 |
| **Flutter** | APP-E2E-TS-001 |
| **Plataformas** | Web (teacher) + Android (student) recomendado |
| **Criterio éxito** | Completion 100% para estudiante; review muestra respuestas |

---

### E2E-008 — Sharing + Guest

| ID | E2E-008 |
|----|---------|
| **Prioridad** | P1 |
| **Pasos** | 1. Autor crea share code. 2. Usuario B canjea (autenticado). 3. Guest canjea código anónimo y practica. 4. Guest ve promo registro |
| **Backend** | SHR-001, GUEST-002 |
| **Flutter** | APP-SHR-001, APP-GUEST-003 |
| **Criterio éxito** | Acceso correcto; límite guest respetado |

---

### E2E-009 — Prep+ compra y simulacro

| ID | E2E-009 |
|----|---------|
| **Prioridad** | P1 |
| **Pasos** | 1. Browse Prep+ hub. 2. Preview gratis. 3. Comprar acceso (IAP o PayPal). 4. Ver en my-accesses. 5. Practicar simulacro completo |
| **Backend** | PREP-010 → PREP-013 |
| **Flutter** | APP-PREP-003 → APP-PREP-006 |
| **Criterio éxito** | Acceso owned/active; simulacro disponible |

---

### E2E-010 — Notificaciones push + in-app

| ID | E2E-010 |
|----|---------|
| **Prioridad** | P1 |
| **Plataformas** | Android + iOS |
| **Trigger** | Webhook payment_issue_pending O assignment due reminder |
| **Pasos** | 1. Registrar device token. 2. Provocar evento. 3. Ver push. 4. Abrir app → notificación in-app |
| **Backend** | NOT-005, NOT-008, NOT-010 |
| **Flutter** | APP-NOT-002, APP-NOT-001 |
| **Criterio éxito** | Push + inbox coherentes |

---

## Flujos E2E secundarios (P2)

| ID | Flujo | Plataformas |
|----|-------|-------------|
| E2E-011 | Import Excel → publicar → practicar | Todas |
| E2E-012 | Cambio contraseña 2 pasos | Todas |
| E2E-013 | Deep link `/join/{code}` → guest | Android, iOS, Web |
| E2E-014 | Deep link `/prep/{slug}?ref=` | Web |
| E2E-015 | Force update (`app-version`) | Android, iOS |
| E2E-016 | Maintenance mode (`/api/status`) | Todas |
| E2E-017 | Admin Prep+ CRUD | Web (admin) |
| E2E-018 | Eliminar cuenta → re-registro mismo email | Todas |

---

## Orden de ejecución recomendado (sprint QA)

### Semana 1 — P0 Backend + Auth/Billing
1. Ejecutar `dotnet test` completo
2. Docs 01 (Auth) + 04 (Billing/Webhooks) casos P0
3. E2E-001, E2E-003, E2E-004

### Semana 2 — P0/P1 Core producto
1. Docs 02 (Quizzes/Practice) + 03 (AI) P0/P1
2. E2E-002, E2E-005
3. `flutter test` + doc 08 casos auth

### Semana 3 — Flutter features
1. Docs 09, 10, 11 casos P1
2. E2E-006, E2E-007, E2E-008
3. Matriz plataformas: marcar ✓/✗ por celda

### Semana 4 — Prep+, notificaciones, regresión
1. Docs 05, 06, 07 restantes
2. E2E-009, E2E-010
3. Re-ejecutar P0 fallidos; sign-off final

---

## Sign-off final (release checklist)

| Área | Doc | P0 | P1 | Auto tests |
|------|-----|:--:|:--:|:----------:|
| Auth | 01, 08 | ☐ | ☐ | ☐ dotnet auth |
| Billing/Webhooks | 04, 08 | ☐ | ☐ | ☐ dotnet billing |
| Quizzes/Practice | 02, 09 | ☐ | ☐ | ☐ dotnet + flutter |
| IA | 03, 09 | ☐ | ☐ | ☐ dotnet ai |
| Teacher/Student | 05, 10 | ☐ | ☐ | ☐ manual |
| Prep+ | 06, 11 | ☐ | ☐ | ☐ dotnet prep |
| Otros | 07, 11 | ☐ | ☐ | ☐ dotnet notif |
| E2E flows | 12 | ☐ | ☐ | ☐ manual matrix |

**Aprobación release:** Responsable QA + Dev lead firman cuando P0 = 100% pass y P1 ≥ 95%.

---

## Comandos rápidos pre-release

```powershell
# Backend
dotnet test tests/CraftQuest.UnitTests
dotnet test tests/CraftQuest.IntegrationTests

# Flutter
cd mobile/craftquest_app
flutter analyze
flutter test

# Build smoke
flutter build web --dart-define=API_BASE_URL=https://api.craftquestai.com
dotnet build src/CraftQuest.Api
```

---

## Trazabilidad requisito → caso

Para auditoría, cada caso usa ID único (`AUTH-001`, `APP-PRAC-001`, `E2E-004`) trazable entre:
- Documento de dominio (01–11)
- Flujo E2E (12)
- Test automatizado (si existe, columna en doc 00 plantilla)
- Bug tracker (campo Bug ID en registro de resultados)
