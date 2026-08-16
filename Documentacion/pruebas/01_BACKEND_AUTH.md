# 01 — Backend: Auth, AccountLinks, OAuth

Controladores: `AuthController` (`api/auth`), `AccountLinksController` (landings HTML).

Tests automatizados existentes:
- `tests/CraftQuest.UnitTests/Auth/AuthServiceEmailVerificationTests.cs` (6)
- `tests/CraftQuest.UnitTests/Auth/AuthServicePasswordResetTests.cs` (3)
- `tests/CraftQuest.UnitTests/Auth/AuthServiceDeleteAccountTests.cs` (3)
- `tests/CraftQuest.IntegrationTests/ApiSmokeTests.cs` (refresh, forgot-password, google stub)

Tests sugeridos (gap):
- `tests/CraftQuest.UnitTests/Auth/JwtTokenServiceTests.cs`
- `tests/CraftQuest.IntegrationTests/Auth/AuthFlowIntegrationTests.cs`

---

## AUTH-001 — Registro exitoso

| Campo | Valor |
|-------|-------|
| **Prioridad** | P0 |
| **Endpoint** | `POST /api/auth/register` |
| **Automatizado** | Parcial → `AuthServiceEmailVerificationTests` |
| **Precondiciones** | Email no registrado |
| **Pasos** | POST body: `{ email, password, displayName, locale }` |
| **Resultado esperado** | 201/200; usuario creado; email de verificación encolado (o log si `Email:Enabled=false`); estado pendiente de verificación |

---

## AUTH-002 — Registro email duplicado

| Prioridad | P0 |
| **Pasos** | Registrar mismo email dos veces |
| **Resultado esperado** | 409 Conflict o error de validación consistente; no duplicar usuario |

---

## AUTH-003 — Verificación de email

| Prioridad | P0 |
| **Endpoint** | `POST /api/auth/verify-email` |
| **Automatizado** | Sí → `AuthServiceEmailVerificationTests` |
| **Pasos** | 1. Registrar. 2. Obtener token (email log / BD). 3. POST verify-email |
| **Resultado esperado** | Email verificado; puede hacer login |

---

## AUTH-004 — Reenvío de verificación

| Prioridad | P1 |
| **Endpoint** | `POST /api/auth/resend-verification` |
| **Automatizado** | Sí → `AuthServiceEmailVerificationTests` |
| **Pasos** | Registrar sin verificar; reenviar |
| **Resultado esperado** | Nuevo token generado; rate limit si aplica |

---

## AUTH-005 — Login email/contraseña exitoso

| Prioridad | P0 |
| **Endpoint** | `POST /api/auth/login` |
| **Pasos** | Login con credenciales válidas y email verificado |
| **Resultado esperado** | `accessToken`, `refreshToken`, expiración; perfil básico |

---

## AUTH-006 — Login sin verificar email

| Prioridad | P0 |
| **Automatizado** | Sí → `AuthServiceEmailVerificationTests` |
| **Resultado esperado** | Error indicando verificación pendiente; no emitir tokens |

---

## AUTH-007 — Login credenciales inválidas

| Prioridad | P0 |
| **Resultado esperado** | 401; mensaje genérico (no revelar si email existe) |

---

## AUTH-008 — Refresh token

| Prioridad | P0 |
| **Endpoint** | `POST /api/auth/refresh` |
| **Automatizado** | Sí → `ApiSmokeTests.Auth_Refresh_ReturnsNewTokens_AndMeAcceptsNewAccessToken` |
| **Pasos** | Login → refresh con refreshToken válido → GET `/api/auth/me` con nuevo access |
| **Resultado esperado** | Nuevo par de tokens; token anterior invalidado o rotado según diseño |

---

## AUTH-009 — Refresh token expirado/revocado

| Prioridad | P0 |
| **Resultado esperado** | 401; requiere login de nuevo |

---

## AUTH-010 — GET /api/auth/me

| Prioridad | P1 |
| **Endpoint** | `GET /api/auth/me` |
| **Pasos** | Bearer token válido |
| **Resultado esperado** | Perfil: id, email, displayName, roles, plan, locale |

---

## AUTH-011 — PATCH /api/auth/me

| Prioridad | P1 |
| **Endpoint** | `PATCH /api/auth/me` |
| **Pasos** | Actualizar displayName, locale, avatar |
| **Resultado esperado** | Cambios persistidos; GET me refleja valores |

---

## AUTH-012 — DELETE /api/auth/me (eliminar cuenta)

| Prioridad | P0 |
| **Automatizado** | Sí → `AuthServiceDeleteAccountTests` |
| **Pasos** | DELETE con token válido |
| **Resultado esperado** | Soft-delete; tokens revocados; datos anonimizados según política |

---

## AUTH-013 — Forgot password

| Prioridad | P0 |
| **Endpoint** | `POST /api/auth/forgot-password` |
| **Automatizado** | Parcial → `ApiSmokeTests`, `AuthServicePasswordResetTests` |
| **Resultado esperado** | 204 siempre (incluso email inexistente); email con token si existe |

---

## AUTH-014 — Reset password

| Prioridad | P0 |
| **Endpoint** | `POST /api/auth/reset-password` |
| **Automatizado** | Sí → `AuthServicePasswordResetTests` |
| **Pasos** | Token válido + nueva contraseña |
| **Resultado esperado** | Contraseña actualizada; login con nueva contraseña funciona |

---

## AUTH-015 — Reset password token expirado

| Prioridad | P0 |
| **Automatizado** | Sí → `AuthServicePasswordResetTests` |
| **Resultado esperado** | 400/401; token invalidado |

---

## AUTH-016 — Change password (flujo confirmación)

| Prioridad | P1 |
| **Endpoints** | `POST /api/auth/change-password`, `POST /api/auth/confirm-password-change` |
| **Pasos** | 1. Solicitar cambio autenticado. 2. Confirmar con token del email |
| **Resultado esperado** | Contraseña cambiada tras confirmación |

---

## AUTH-017 — OAuth Google

| Prioridad | P0 |
| **Endpoint** | `POST /api/auth/google` |
| **Precondiciones** | ID token Google válido (client ID configurado) |
| **Pasos** | Enviar `{ idToken }` |
| **Resultado esperado** | Login o registro; tokens emitidos; email verificado si Google lo confirma |
| **Automatizado** | No → sugerido: `AuthServiceGoogleOAuthTests.cs` con mock validator |

---

## AUTH-018 — OAuth Apple

| Prioridad | P0 |
| **Endpoint** | `POST /api/auth/apple` |
| **Precondiciones** | ID token Apple válido, BundleId correcto |
| **Resultado esperado** | Igual que Google; manejo de email privado de Apple |
| **Automatizado** | No → sugerido: `AuthServiceAppleOAuthTests.cs` |

---

## AUTH-019 — GET oauth-config

| Prioridad | P2 |
| **Endpoint** | `GET /api/auth/oauth-config` (AllowAnonymous) |
| **Resultado esperado** | Client IDs públicos para la app; sin secretos |

---

## AUTH-020 — Consentimiento parental (registro menor)

| Prioridad | P0 |
| **Endpoints** | `POST /api/auth/confirm-parental-consent`, `POST /api/auth/resend-parental-consent` |
| **Pasos** | 1. Registrar usuario menor (si aplica edad). 2. Estado pending parental. 3. Confirmar con token |
| **Resultado esperado** | Cuenta activa tras consentimiento; bloqueada antes |

---

## AccountLinks — Landings HTML

| ID | Ruta | Prioridad | Pasos | Esperado |
|----|------|-----------|-------|----------|
| LINK-001 | `GET /verify-email/{token}` | P1 | Abrir en navegador token válido | Página confirma verificación o redirige a app |
| LINK-002 | `GET /reset-password/{token}` | P1 | Token válido | Formulario o deep link a app |
| LINK-003 | `GET /confirm-password-change/{token}` | P2 | Token válido | Confirmación exitosa |
| LINK-004 | `GET /parental-consent/{token}` | P0 | Token válido | Consentimiento registrado |
| LINK-005 | Token inválido/expirado | P1 | Cualquier landing | Mensaje de error claro; no 500 |

---

## Seguridad transversal

| ID | Caso | Prioridad | Esperado |
|----|------|-----------|----------|
| SEC-001 | Endpoint protegido sin Bearer | P0 | 401 |
| SEC-002 | Token JWT manipulado | P0 | 401 |
| SEC-003 | Token expirado | P0 | 401 |
| SEC-004 | CORS en auth endpoints | P2 | Headers correctos para app web |
| SEC-005 | Rate limiting registro/login | P1 | No abuso masivo (si configurado) |

---

## Checklist de sign-off Auth

- [ ] AUTH-001 a AUTH-018 ejecutados en staging
- [ ] OAuth probado en Android, iOS y Web con client IDs de prod/staging
- [ ] AccountLinks abren correctamente desde email real
- [ ] `dotnet test --filter Auth` en verde
- [ ] Consentimiento parental verificado en Android (Play Age Signals) + backend
