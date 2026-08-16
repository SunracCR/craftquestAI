# 11 — Flutter: Notifications, Profile, Sharing, Home, Prep+, Compliance, Shell

Pantallas: `notifications_page`, `notification_preferences_page`, `profile_page`, `change_password_page`, `confirm_password_change_page`, `payment_history_page`, `redeem_code_page`, `accessible_quizzes_page`, `home_page`, `prep_plus/*`, `parental_consent_required_page`, `main_shell_page`.

Tests automatizados existentes: ninguno directo en estas features.

Tests sugeridos:
- `test/features/notifications/notifications_cubit_test.dart`
- `test/features/sharing/sharing_repository_test.dart`
- `test/features/prep_plus/prep_preview_grader_test.dart`
- `test/features/compliance/age_signal_service_test.dart`

---

## Shell / Navegación

### APP-SHELL-001 — Bottom navigation

| Prioridad | P1 |
| **Pantalla** | `main_shell_page.dart` |
| **Pasos** | Cambiar entre tabs |
| **Resultado esperado** | Lazy load; estado preservado por tab |

### APP-SHELL-002 — Refresh post-checkout

| **Pasos** | Completar compra → volver a shell |
| **Resultado esperado** | Billing/profile refrescados (`MainShellTabSignal`) |

### APP-SHELL-003 — Tabs según rol

| **Usuario normal** | Home, Prep+, Perfil (3 tabs) |
| **Teacher** | + tab Teacher (4 tabs) |

---

## Home

### APP-HOME-001 — Dashboard accesos

| **Pantalla** | `home_page.dart` |
| **Resultado esperado** | Links a quizzes, offline, sharing, AI, billing, assignments |

### APP-HOME-002 — Badge notificaciones unread

| **Pasos** | Tener notificaciones sin leer |
| **Resultado esperado** | Contador visible en icono |

### APP-HOME-003 — Banner teacher dismiss

| **Storage** | `HomeTeacherBannerPrefs` |
| **Resultado esperado** | Banner no reaparece tras dismiss |

### APP-HOME-004 — Contador offline downloads

| **Plataforma** | No Web |
| **Resultado esperado** | Muestra N quizzes descargados |

---

## Notifications

### APP-NOT-001 — Bandeja in-app

| Prioridad | P1 |
| **Pantalla** | `notifications_page.dart` |
| **Pasos** | Abrir desde Home |
| **Resultado esperado** | Lista paginada; marcar leída |

### APP-NOT-002 — Push notification (dispositivo real)

| Prioridad | P0 |
| **Precondiciones** | FCM configurado; device token registrado |
| **Trigger** | Webhook payment_issue_pending o assignment reminder |
| **Resultado esperado** | Push recibido; tap abre app/notificación |

### APP-NOT-003 — Preferencias

| **Pantalla** | `notification_preferences_page.dart` |
| **Pasos** | Toggle email/push/in-app por tipo |
| **Resultado esperado** | Cambios persistidos vía API |

### APP-NOT-004 — NotificationsCubit estados

| **Automatizado** | No → `notifications_cubit_test.dart` |
| **Estados** | loading, loaded, error, pagination |

---

## Profile

### APP-PROF-001 — Ver perfil

| **Pantalla** | `profile_page.dart` |
| **Resultado esperado** | Nombre, email, plan, idioma, avatar |

### APP-PROF-002 — Cambiar avatar

| **Pasos** | Tap avatar → picker → upload |
| **Resultado esperado** | Imagen actualizada vía Media API |

### APP-PROF-003 — Cambiar contraseña

| **Pantallas** | `change_password_page`, `confirm_password_change_page` |
| **Flujo** | 2 pasos con confirmación |

### APP-PROF-004 — Historial pagos

| **Pantalla** | `payment_history_page.dart` |

### APP-PROF-005 — Logout / delete account

| Ver APP-AUTH-009, APP-AUTH-010 en doc 08 |

---

## Sharing

### APP-SHR-001 — Canjear código

| Prioridad | P1 |
| **Pantalla** | `redeem_code_page.dart` |
| **Pasos** | Ingresar código válido |
| **Resultado esperado** | Quiz accesible en lista |

### APP-SHR-002 — Quizzes accesibles

| **Pantalla** | `accessible_quizzes_page.dart` |
| **Resultado esperado** | Agrupados por sharer |

### APP-SHR-003 — Crear código (sheet)

| **Widget** | `create_share_code_sheet.dart` (desde quiz detail) |

### APP-SHR-004 — Invitar usuarios (sheet)

| **Widget** | `invite_quiz_users_sheet.dart` |

### APP-SHR-005 — Quitar acceso

| **Pasos** | Accessible list → eliminar |
| **Resultado esperado** | Quiz ya no accesible |

---

## Prep+ (UI)

### APP-PREP-001 — Hub Prep+

| **Pantalla** | `prep_plus_hub_page.dart` |
| **Tab** | Prep+ en shell |

### APP-PREP-002 — Navegar categorías

| **Pantallas** | `PrepPlusCategoryPickerPage`, `prep_plus_category_page` |

### APP-PREP-003 — Detalle item

| **Pantalla** | `prep_plus_item_detail_page.dart` |
| **Resultado esperado** | Opciones preview, compra, practicar (si owned) |

### APP-PREP-004 — Preview gratuita

| **Pantallas** | `prep_plus_preview_page`, `prep_plus_preview_result_page` |
| **Automatizado** | No → `prep_preview_grader_test.dart` |

### APP-PREP-005 — Preview pública (sin login)

| **Pantalla** | `prep_plus_public_preview_page.dart` |
| **Deep link** | `prep_referral_launch.dart` (Web) |

### APP-PREP-006 — Mis accesos

| **Pantalla** | `prep_plus_my_accesses_page.dart` |

### APP-PREP-007 — Admin Prep+ (ContentAdmin)

| **Pantallas** | `admin/prep_plus_admin_*` |
| **Precondiciones** | Rol admin |
| **Pasos** | CRUD categorías e items |

---

## Compliance (Android)

### APP-COMP-001 — Play Age Signals bloqueo

| Prioridad | P0 |
| **Plataforma** | Android |
| **Pantalla** | `parental_consent_required_page.dart` |
| **Precondiciones** | Cuenta supervisada sin consentimiento |
| **Resultado esperado** | App bloqueada hasta consentimiento |

### APP-COMP-002 — Re-chequeo manual

| **Pasos** | Botón reintentar verificación edad |
| **Storage** | `age_signal_service.dart`, `age_collection_storage.dart` |

---

## Plugins smoke (regresión upgrades)

### APP-PLG-001

| **Automatizado** | Sí → `upgraded_plugins_compatibility_test.dart` |
| **Plugins** | share_plus, sign_in_with_apple, image_picker, desktop_drop |

---

## Checklist sign-off Otros Flutter

- [ ] Navegación shell 3/4 tabs correcta
- [ ] Notificaciones in-app + push en dispositivo
- [ ] Profile completo (avatar, idioma, logout)
- [ ] Sharing redeem + accessible list
- [ ] Prep+ browse → preview → compra → practicar
- [ ] Compliance Android probado en dispositivo
- [ ] Home muestra badges correctos
