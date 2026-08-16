# 07 — Backend: Notifications, Sharing, Media, Status y Jobs

Controladores: `NotificationsController`, `SharingController`, `JoinController`, `MediaController`, `AppVersionController`, `StatusController`, `OfflinePackagesController` (ver también doc 02).

Background jobs:
- `NotificationReminderHostedService` (1h)
- `GuestCleanupHostedService` (30 min)
- `DatabaseKeepWarmHostedService` (configurable)
- `PracticeSnapshotDeferredWriterHostedService` (continuo)

Tests automatizados existentes:
- `Notifications/NotificationServiceTests.cs` (8)
- `Notifications/NotificationTextBuilderTests.cs` (2 + theory i18n)
- `Sharing/ShareCodeServiceTests.cs` (7)
- `Offline/OfflinePackageCryptoServiceTests.cs` (4)

Tests sugeridos:
- `tests/CraftQuest.UnitTests/Notifications/NotificationPublisherTests.cs`
- `tests/CraftQuest.UnitTests/Media/MediaServiceTests.cs`
- `tests/CraftQuest.UnitTests/App/AppVersionServiceTests.cs`
- `tests/CraftQuest.UnitTests/Guest/GuestCleanupHostedServiceTests.cs`

---

## Notifications

### NOT-001 — Listar notificaciones

| Prioridad | P1 |
| **Endpoint** | `GET /api/notifications` |
| **Query** | cursor, pageSize |
| **Automatizado** | Parcial → `NotificationServiceTests` |

### NOT-002 — Contador unread

| **Endpoint** | `GET /api/notifications/unread-count` |

### NOT-003 — Marcar como leída

| **Endpoint** | `POST /api/notifications/{id}/read` |

### NOT-004 — Marcar todas leídas

| **Endpoint** | `POST /api/notifications/read-all` |

### NOT-005 — Registrar device token FCM

| Prioridad | P0 |
| **Endpoint** | `POST /api/notifications/device-tokens` |
| **Body** | `{ token, platform }` |
| **Precondiciones** | `Push:Enabled=true` en staging para push real |

### NOT-006 — Eliminar device token

| **Endpoint** | `DELETE /api/notifications/device-tokens` |

### NOT-007 — Preferencias GET/PUT

| **Endpoints** | `GET/PUT /api/notifications/preferences` |
| **Automatizado** | Parcial → `NotificationServiceTests` (email defaults) |
| **Verificar** | `payment_issue_pending` tiene email on por defecto |

### NOT-008 — Notificación payment_issue_pending

| Prioridad | P0 |
| **Trigger** | Webhook Google Play tipo 5/6 |
| **Automatizado** | Parcial → `NotificationTextBuilderTests`, webhook tests |
| **Verificar** | Texto en es/en/pt; push si habilitado |

### NOT-009 — Dedup de notificaciones

| **Automatizado** | Sí → `NotificationServiceTests` |

### NOT-010 — NotificationReminderHostedService

| **Tipo** | Manual |
| **Pasos** | Assignment próximo a vencer; suscripción por expirar |
| **Resultado esperado** | Recordatorio en outbox/notificaciones |

---

## Sharing

### SHR-001 — Canjear código

| Prioridad | P1 |
| **Endpoint** | `POST /api/sharing/share-codes/redeem` |
| **Automatizado** | Sí → `ShareCodeServiceTests` |
| **Pasos** | `{ code }` válido |
| **Resultado esperado** | Acceso al quiz en accessible-quizzes |

### SHR-002 — Límite free al canjear

| **Automatizado** | Sí → `ShareCodeServiceTests` |
| **Resultado esperado** | Error al exceder límite plan free |

### SHR-003 — Listar accessible quizzes

| **Endpoint** | `GET /api/sharing/accessible-quizzes` |

### SHR-004 — Quitar acceso

| **Endpoint** | `DELETE /api/sharing/accessible-quizzes/{quizId}` |

---

## Join / Deep links

### JOIN-001 — Preview join API

| **Endpoint** | `GET /api/join/{code}/preview` (AllowAnonymous) |
| **Resultado esperado** | Metadatos quiz para landing |

### JOIN-002 — Landing HTML

| **Rutas** | `GET /join`, `GET /join/{code}` |

### JOIN-003 — assetlinks.json

| **Endpoint** | `GET /.well-known/assetlinks.json` |
| **Plataforma** | Android App Links |

### JOIN-004 — apple-app-site-association

| **Endpoint** | `GET /.well-known/apple-app-site-association` |
| **Plataforma** | iOS Universal Links |

---

## Media

### MED-001 — Upload imagen

| Prioridad | P1 |
| **Endpoint** | `POST /api/media/upload` (multipart) |
| **Límite** | MaxUploadBytes (~6 MB) |
| **Automatizado** | No → `MediaServiceTests.cs` |

### MED-002 — Descargar media

| **Endpoint** | `GET /api/media/{mediaAssetId}/file` |
| **Auth** | JWT o headers guest |
| **Storage** | local (dev) / azure (prod) |

### MED-003 — Acceso no autorizado

| **Resultado esperado** | 403/404 sin permiso al quiz/pregunta |

### MED-004 — Imagen en pregunta de práctica

| **Pasos** | Quiz con imagen → iniciar práctica → cargar media en snapshot |

---

## App Version / Status

### VER-001 — GET app-version

| Prioridad | P1 |
| **Endpoint** | `GET /api/app-version?platform=android` |
| **Resultado esperado** | minVersion, forceUpdate flag |

### VER-002 — PUT app-version (admin)

| **Endpoint** | `PUT /api/app-version/{platform}` |
| **Auth** | ContentAdmin |

### STA-001 — GET status

| **Endpoint** | `GET /api/status` |
| **Resultado esperado** | maintenanceMode, message, feature flags |

### STA-002 — Health check

| **Endpoint** | `GET /health` |
| **Automatizado** | Sí → `ApiSmokeTests.Health_ReturnsSuccess` |

---

## Background jobs

### JOB-001 — GuestCleanupHostedService

| **Intervalo** | 30 min |
| **Pasos** | Crear visita guest expirada |
| **Resultado esperado** | Visita purgada de BD |

### JOB-002 — DatabaseKeepWarmHostedService

| **Config** | `Practice:EnableDatabaseKeepWarm` |
| **Tipo** | Smoke — verificar no errores en logs |

### JOB-003 — PracticeSnapshotDeferredWriterHostedService

| **Pasos** | Iniciar sesión con muchas preguntas |
| **Resultado esperado** | Opciones insertadas async; sesión usable |

### JOB-004 — NotificationReminderHostedService

| Ver NOT-010 |

---

## Checklist sign-off Otros

- [ ] Push FCM recibido en dispositivo real (staging)
- [ ] Preferencias de notificación persisten
- [ ] Share code redeem + accessible list
- [ ] Join deep links Android/iOS
- [ ] Media upload + serve en pregunta
- [ ] App version force update probado en app
- [ ] Guest cleanup verificado
