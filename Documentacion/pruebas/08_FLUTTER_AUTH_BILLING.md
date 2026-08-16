# 08 — Flutter: Auth y Billing

Pantallas: `login_page`, `register_page`, `forgot_password_page`, `reset_password_page`, `verify_email_*`, `parental_consent_pending_page`, `upgrade_plan_page`, `teacher_upgrade_page`, `ai_credit_packs_page`, `paypal_return_page`.

Tests automatizados existentes:
- `test/features/auth/auth_bloc_offline_session_test.dart` (AuthBloc offline, JwtUtils)
- `test/widget_test.dart` (LoginPage smoke — **falla overflow** en algunos viewports)
- `test/features/billing/purchase_history_item_model_test.dart`

Tests sugeridos:
- `test/features/auth/auth_bloc_login_test.dart`
- `test/features/billing/billing_repository_test.dart`
- `test/features/billing/payment_platform_test.dart`
- `integration_test/auth_billing_flow_test.dart`

---

## Matriz de pagos por plataforma

| Plataforma | Suscripción Pro/Teacher | Créditos IA | Prep+ |
|------------|-------------------------|-------------|-------|
| Android | Google Play IAP | IAP consumible | IAP consumible |
| iOS | App Store IAP | IAP consumible | IAP consumible |
| Web | PayPal checkout | PayPal | PayPal |
| Windows/macOS/Linux | PayPal | PayPal | PayPal |

---

## Auth — Registro y login

### APP-AUTH-001 — Registro email

| Prioridad | P0 |
| **Pantalla** | `register_page.dart` |
| **Plataforma** | Todas |
| **Pasos** | Completar formulario → enviar |
| **Resultado esperado** | Navega a `verify_email_pending_page`; email enviado |

### APP-AUTH-002 — Verificación email

| **Pantalla** | `verify_email_page.dart` |
| **Pasos** | Ingresar código o abrir deep link |
| **Resultado esperado** | Cuenta verificada; puede login |

### APP-AUTH-003 — Login email/contraseña

| **Pantalla** | `login_page.dart` |
| **Automatizado** | Parcial → `widget_test.dart` (arreglar overflow) |
| **Resultado esperado** | Navega a `main_shell_page`; tokens en secure storage |

### APP-AUTH-004 — Login Google OAuth

| **Plataforma** | Android, iOS, Web, macOS, Windows |
| **Pasos** | Tap Google → flujo OAuth nativo/web |
| **Resultado esperado** | Sesión autenticada |

### APP-AUTH-005 — Login Apple

| **Plataforma** | iOS, macOS, Web (si configurado) |
| **Resultado esperado** | Sesión autenticada |

### APP-AUTH-006 — Forgot / reset password

| **Pantallas** | `forgot_password_page`, `reset_password_page` |
| **Pasos** | Solicitar reset → abrir link → nueva contraseña |
| **Plataforma Web** | Deep link `account_link_launch.dart` |

### APP-AUTH-007 — Consentimiento parental pendiente

| **Pantalla** | `parental_consent_pending_page.dart` |
| **Resultado esperado** | Bloqueo hasta aprobación |

### APP-AUTH-008 — Sesión offline

| **Automatizado** | Sí → `auth_bloc_offline_session_test.dart` |
| **Pasos** | Login online → cortar red → abrir app |
| **Resultado esperado** | Perfil cacheado; badge offline si aplica |

### APP-AUTH-009 — Logout

| **Pantalla** | `profile_page.dart` |
| **Resultado esperado** | Tokens borrados; vuelve a login |

### APP-AUTH-010 — Eliminar cuenta

| **Pasos** | Profile → delete account → confirmar |
| **Resultado esperado** | Cuenta eliminada; logout |

### APP-AUTH-011 — Cambio de idioma (en/es/pt)

| **Storage** | `locale_controller.dart` → SharedPreferences |
| **Resultado esperado** | UI cambia idioma; strings no hardcoded |

---

## Billing — Upgrade plan

### APP-BILL-001 — Ver planes disponibles

| **Pantalla** | `upgrade_plan_page.dart` |
| **Prioridad** | P0 |
| **Resultado esperado** | Muestra Free vs Pro con precios |

### APP-BILL-002 — Compra Pro Android (IAP)

| **Plataforma** | Android |
| **Precondiciones** | Licencia de prueba Play Console |
| **Pasos** | Seleccionar plan → Google Play dialog → comprar |
| **Resultado esperado** | `verify-purchase` OK; perfil muestra plan Pro |

### APP-BILL-003 — Compra Pro iOS (IAP)

| **Plataforma** | iOS |
| **Precondiciones** | Sandbox tester App Store |

### APP-BILL-004 — Compra Pro Web (PayPal)

| **Plataforma** | Web |
| **Pasos** | PayPal checkout → redirect → `paypal_return_page` |
| **Storage** | `PendingPayPalPaymentStore` si interrumpe |
| **Resultado esperado** | Plan activado; shell refresca billing |

### APP-BILL-005 — Compra Teacher plan

| **Pantalla** | `teacher_upgrade_page.dart` |
| **Resultado esperado** | Plan teacher + tab Teacher visible en shell |

### APP-BILL-006 — Cancelar auto-renovación

| **Flujo** | `subscription_cancel_flow.dart` |
| **Resultado esperado** | UI confirma cancel at period end |

### APP-BILL-007 — Reanudar auto-renovación

| **Flujo** | `subscription_resume_flow.dart` |

### APP-BILL-008 — Compra créditos IA

| **Pantalla** | `ai_credit_packs_page.dart` |
| **Plataformas** | IAP móvil / PayPal web |
| **Resultado esperado** | Créditos incrementados en perfil |

### APP-BILL-009 — PaymentIssuePending en UI

| Prioridad | P0 |
| **Precondiciones** | Webhook tipo 5/6 aplicado |
| **Pasos** | Intentar generación IA |
| **Resultado esperado** | Mensaje de problema de pago; notificación in-app |

### APP-BILL-010 — Historial de pagos

| **Pantalla** | `payment_history_page.dart` |
| **Automatizado** | Parcial → `purchase_history_item_model_test.dart` |
| **Resultado esperado** | Lista compras con fechas y montos |

### APP-BILL-011 — PayPal return con pago pendiente

| **Pantalla** | `paypal_return_page.dart` |
| **Pasos** | Interrumpir checkout → reabrir return URL |
| **Storage** | `PendingPayPalPaymentStore` recupera estado |

---

## Prep+ compras (referencia cruzada)

Ver también `06_BACKEND_PREP_PLUS.md` y casos en `prep_plus_item_detail_page` en doc 09/11.

### APP-PREP-PAY-001 — Compra Prep+ IAP Android

| **Plataforma** | Android |
| **Pantalla** | `prep_plus_item_detail_page.dart` |

### APP-PREP-PAY-002 — Compra Prep+ PayPal Web

| **Plataforma** | Web |

---

## Checklist sign-off Auth/Billing Flutter

- [ ] Registro + verificación + login en Android, iOS, Web
- [ ] OAuth Google en al menos 2 plataformas
- [ ] Compra Pro verificada en Android (IAP) y Web (PayPal)
- [ ] Créditos IA comprados y reflejados
- [ ] Cancel/resume auto-renew probado
- [ ] Sesión offline verificada manualmente
- [ ] `flutter test test/features/auth/` en verde tras fix overflow login
