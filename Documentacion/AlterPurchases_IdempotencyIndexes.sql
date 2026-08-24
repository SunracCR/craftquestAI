-- Idempotencia de compras y una sola suscripción activa por usuario.
-- Ejecutar de forma idempotente en Azure SQL.

SET NOCOUNT ON;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'UX_Purchases_ProviderTransaction'
      AND object_id = OBJECT_ID('billing.Purchases'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_Purchases_ProviderTransaction
        ON billing.Purchases (ProviderCode, ProviderTransactionId)
        WHERE ProviderTransactionId IS NOT NULL;
END;
GO

/* Normalizar duplicados antes del índice único.
   Conserva la suscripción active más reciente (StartedAt, CreatedAt). */
IF EXISTS (
    SELECT 1
    FROM billing.UserSubscriptions
    WHERE Status = N'active'
    GROUP BY UserId
    HAVING COUNT(*) > 1)
BEGIN
    PRINT N'Corrigiendo usuarios con más de una suscripción active...';

    ;WITH RankedActive AS (
        SELECT
            UserSubscriptionId,
            UserId,
            ROW_NUMBER() OVER (
                PARTITION BY UserId
                ORDER BY StartedAt DESC, CreatedAt DESC, UserSubscriptionId DESC
            ) AS rn
        FROM billing.UserSubscriptions
        WHERE Status = N'active'
    )
    UPDATE s
    SET
        Status = N'cancelled',
        EndsAt = COALESCE(s.EndsAt, SYSUTCDATETIME()),
        AutoRenewEnabled = 0,
        CancelAtPeriodEnd = 0
    FROM billing.UserSubscriptions s
    INNER JOIN RankedActive r ON r.UserSubscriptionId = s.UserSubscriptionId
    WHERE r.rn > 1;

    PRINT CONCAT(N'Suscripciones duplicadas canceladas: ', @@ROWCOUNT);
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'UX_UserSubscriptions_OneActivePerUser'
      AND object_id = OBJECT_ID('billing.UserSubscriptions'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_UserSubscriptions_OneActivePerUser
        ON billing.UserSubscriptions (UserId)
        WHERE Status = N'active';
END;
GO
