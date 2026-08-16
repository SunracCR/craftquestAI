/* Payment issue flag for Google Play on hold / grace period webhooks.
   Ejecutar una vez en Azure SQL / SQL Server. Re-ejecutable (idempotente). */

SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('billing.UserSubscriptions', 'PaymentIssuePending') IS NULL
BEGIN
    ALTER TABLE billing.UserSubscriptions
    ADD PaymentIssuePending BIT NOT NULL
        CONSTRAINT DF_UserSubscriptions_PaymentIssuePending DEFAULT (0);
END
GO

PRINT N'billing.UserSubscriptions: PaymentIssuePending listo.';
GO
