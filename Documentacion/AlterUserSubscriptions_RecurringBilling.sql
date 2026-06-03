/* Suscripciones recurrentes: ciclo, auto-renovación y webhooks.
   Ejecutar una vez en Azure SQL / SQL Server. Re-ejecutable (idempotente). */

SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('billing.UserSubscriptions', 'BillingCycle') IS NULL
BEGIN
    ALTER TABLE billing.UserSubscriptions
    ADD BillingCycle NVARCHAR(20) NOT NULL
        CONSTRAINT DF_UserSubscriptions_BillingCycle DEFAULT (N'monthly');
END
GO

IF COL_LENGTH('billing.UserSubscriptions', 'AutoRenewEnabled') IS NULL
BEGIN
    ALTER TABLE billing.UserSubscriptions
    ADD AutoRenewEnabled BIT NOT NULL
        CONSTRAINT DF_UserSubscriptions_AutoRenewEnabled DEFAULT (1);
END
GO

IF COL_LENGTH('billing.UserSubscriptions', 'CancelAtPeriodEnd') IS NULL
BEGIN
    ALTER TABLE billing.UserSubscriptions
    ADD CancelAtPeriodEnd BIT NOT NULL
        CONSTRAINT DF_UserSubscriptions_CancelAtPeriodEnd DEFAULT (0);
END
GO

IF COL_LENGTH('billing.UserSubscriptions', 'LastPaymentAt') IS NULL
BEGIN
    ALTER TABLE billing.UserSubscriptions
    ADD LastPaymentAt DATETIME2(7) NULL;
END
GO

IF OBJECT_ID('billing.ProviderWebhookEvents', 'U') IS NULL
BEGIN
    CREATE TABLE billing.ProviderWebhookEvents (
        ProviderWebhookEventId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_ProviderWebhookEvents PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
        ProviderCode NVARCHAR(50) NOT NULL,
        EventId NVARCHAR(200) NOT NULL,
        EventType NVARCHAR(100) NOT NULL,
        ProcessedAt DATETIME2(7) NOT NULL
            CONSTRAINT DF_ProviderWebhookEvents_ProcessedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_ProviderWebhookEvents_Provider_Event
            UNIQUE (ProviderCode, EventId)
    );
END
GO

/* Suscripciones activas de pago sin fin de periodo: +1 mes desde StartedAt */
UPDATE billing.UserSubscriptions
SET EndsAt = DATEADD(MONTH, 1, StartedAt),
    BillingCycle = N'monthly',
    AutoRenewEnabled = 1,
    CancelAtPeriodEnd = 0
WHERE Status = N'active'
  AND EndsAt IS NULL
  AND ProviderCode IS NOT NULL
  AND ProviderCode NOT IN (N'internal', N'manual_admin', N'manual_test');
GO

IF COL_LENGTH('billing.Purchases', 'BillingCycle') IS NULL
BEGIN
    ALTER TABLE billing.Purchases
    ADD BillingCycle NVARCHAR(20) NULL;
END
GO

PRINT N'billing.UserSubscriptions: columnas de renovación automática listas.';
GO
