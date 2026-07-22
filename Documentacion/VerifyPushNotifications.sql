-- Verificación de push FCM (ejecutar en Azure SQL / prod).
-- Las notificaciones in-app viven en core.Notifications; push usa core.DeviceTokens + FCM.

-- 1) Tokens registrados por usuario (tras login en Android/iOS)
SELECT
    dt.UserId,
    u.Email,
    dt.Platform,
    LEFT(dt.Token, 24) AS TokenPrefix,
    dt.LastSeenAt
FROM core.DeviceTokens dt
INNER JOIN core.Users u ON u.UserId = dt.UserId
ORDER BY dt.LastSeenAt DESC;

-- 2) Usuario concreto (reemplazar GUID)
-- SELECT Platform, LEFT(Token, 24) AS TokenPrefix, LastSeenAt
-- FROM core.DeviceTokens
-- WHERE UserId = '00000000-0000-0000-0000-000000000000'
-- ORDER BY LastSeenAt DESC;

-- 3) Preferencias push por tipo
-- SELECT NotificationType, PushEnabled, InAppEnabled
-- FROM core.NotificationPreferences
-- WHERE UserId = '00000000-0000-0000-0000-000000000000';

-- 4) Notificaciones in-app recientes (canal distinto al push)
SELECT TOP 20
    NotificationId,
    UserId,
    Type,
    Title,
    IsRead,
    CreatedAt
FROM core.Notifications
ORDER BY CreatedAt DESC;
