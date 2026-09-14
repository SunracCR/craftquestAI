/* Repara estado sucio tras DowngradeUserToFreePlan.sql y deja al usuario en Free limpio.
 *
 * Caso típico: se bajó a free en CraftQuest pero quedaron compras abiertas, más de una
 * suscripción active, rol teacher, o la suscripción de pago sigue viva en PayPal/tienda.
 *
 * Ajusta @Email. @DryRun = 1 (default) solo muestra; @DryRun = 0 aplica.
 *
 * Qué hace (@DryRun = 0):
 *   1. Cancela TODAS las UserSubscriptions active (paid y free) y deja UNA sola free
 *      (ProviderCode = internal, monthly, sin auto-renew).
 *   2. Pasa a cancelled las Purchases pending / awaiting_payment de tipo subscription.
 *   3. Quita el rol teacher.
 *   4. Lista ProviderSubscriptionId de suscripciones de pago (activas o ya canceladas
 *      en BD) para cancelarlas también en PayPal / Google Play / App Store.
 *
 * Qué NO hace:
 *   - No borra Purchases validated / refunded / rejected (historial + índice único).
 *   - No toca CreditLedger (ni ai ni ai_purchased).
 *   - NO cancela cobros en PayPal, Google Play ni App Store.
 *
 * Re-ejecutable.
 */

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Email NVARCHAR(320) = N'carlossm01@gmail.com';   -- <-- cambiar
DECLARE @DryRun BIT = 1;                                  -- 1 = vista previa, 0 = aplicar

DECLARE @UserId UNIQUEIDENTIFIER = (
    SELECT TOP (1) UserId
    FROM core.Users
    WHERE (Email = @Email OR EmailNormalized = UPPER(LTRIM(RTRIM(@Email))))
      AND DeletedAt IS NULL
);

IF @UserId IS NULL
BEGIN
    RAISERROR(N'Usuario no encontrado (o cuenta eliminada): %s', 16, 1, @Email);
    RETURN;
END;

DECLARE @FreePlanId INT;

SELECT @FreePlanId = PlanId
FROM billing.Plans
WHERE Code = N'free' AND IsActive = 1;

IF @FreePlanId IS NULL
BEGIN
    RAISERROR(N'Plan free no encontrado en billing.Plans.', 16, 1);
    RETURN;
END;

DECLARE @Now DATETIME2(7) = SYSUTCDATETIME();
DECLARE @TeacherRoleId INT = (
    SELECT RoleId FROM core.Roles WHERE Code = N'teacher'
);

PRINT N'--- RepairUserBillingAfterFreeDowngrade ---';
PRINT N'Email: ' + @Email;
PRINT N'UserId: ' + CONVERT(NVARCHAR(36), @UserId);
PRINT N'DryRun: ' + CASE WHEN @DryRun = 1 THEN N'SÍ (no escribe)' ELSE N'NO (APLICANDO)' END;
PRINT N'';

PRINT N'=== Suscripciones actuales ===';
SELECT
    s.UserSubscriptionId,
    p.Code AS PlanCode,
    s.Status,
    s.BillingCycle,
    s.ProviderCode,
    s.ProviderSubscriptionId,
    s.AutoRenewEnabled,
    s.CancelAtPeriodEnd,
    s.PaymentIssuePending,
    s.StartedAt,
    s.EndsAt,
    s.LastPaymentAt,
    s.CreatedAt
FROM billing.UserSubscriptions s
JOIN billing.Plans p ON p.PlanId = s.PlanId
WHERE s.UserId = @UserId
ORDER BY
    CASE WHEN s.Status = N'active' THEN 0 ELSE 1 END,
    s.StartedAt DESC;

PRINT N'';
PRINT N'=== Compras (todas) ===';
SELECT
    p.PurchaseId,
    p.ProductCode,
    p.ProductType,
    p.ProviderCode,
    p.ProviderTransactionId,
    p.Status,
    p.BillingCycle,
    p.Amount,
    p.CurrencyCode,
    p.PurchasedAt,
    p.CreatedAt
FROM billing.Purchases p
WHERE p.UserId = @UserId
ORDER BY p.CreatedAt DESC;

PRINT N'';
PRINT N'=== Roles y créditos ===';
SELECT
    u.Email,
    STRING_AGG(r.Code, N', ') WITHIN GROUP (ORDER BY r.Code) AS Roles,
    ISNULL((
        SELECT SUM(cl.Delta)
        FROM billing.CreditLedger cl
        WHERE cl.UserId = u.UserId AND cl.CreditType = N'ai'
    ), 0) AS AiPlanCreditsBalance,
    ISNULL((
        SELECT SUM(cl.Delta)
        FROM billing.CreditLedger cl
        WHERE cl.UserId = u.UserId AND cl.CreditType = N'ai_purchased'
    ), 0) AS AiPurchasedCreditsBalance
FROM core.Users u
LEFT JOIN core.UserRoles ur ON ur.UserId = u.UserId
LEFT JOIN core.Roles r ON r.RoleId = ur.RoleId
WHERE u.UserId = @UserId
GROUP BY u.Email, u.UserId;

DROP TABLE IF EXISTS #PaidProviderIds;
DROP TABLE IF EXISTS #OpenSubscriptionPurchases;

CREATE TABLE #PaidProviderIds (
    PlanCode NVARCHAR(40) NOT NULL,
    Status NVARCHAR(30) NOT NULL,
    ProviderCode NVARCHAR(50) NULL,
    ProviderSubscriptionId NVARCHAR(300) NOT NULL,
    BillingCycle NVARCHAR(20) NULL,
    StartedAt DATETIME2(7) NULL,
    EndsAt DATETIME2(7) NULL
);

CREATE TABLE #OpenSubscriptionPurchases (
    PurchaseId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY
);

INSERT INTO #PaidProviderIds (
    PlanCode, Status, ProviderCode, ProviderSubscriptionId, BillingCycle, StartedAt, EndsAt)
SELECT
    p.Code,
    s.Status,
    s.ProviderCode,
    s.ProviderSubscriptionId,
    s.BillingCycle,
    s.StartedAt,
    s.EndsAt
FROM billing.UserSubscriptions s
JOIN billing.Plans p ON p.PlanId = s.PlanId
WHERE s.UserId = @UserId
  AND p.Code <> N'free'
  AND NULLIF(LTRIM(RTRIM(s.ProviderSubscriptionId)), N'') IS NOT NULL
  AND ISNULL(s.ProviderCode, N'') NOT IN (N'internal', N'manual_admin', N'manual_test');

INSERT INTO #OpenSubscriptionPurchases (PurchaseId)
SELECT p.PurchaseId
FROM billing.Purchases p
WHERE p.UserId = @UserId
  AND p.ProductType = N'subscription'
  AND p.Status IN (N'pending', N'awaiting_payment');

DECLARE @ActiveCount INT = (
    SELECT COUNT(*)
    FROM billing.UserSubscriptions
    WHERE UserId = @UserId AND Status = N'active'
);
DECLARE @ActiveFreeCount INT = (
    SELECT COUNT(*)
    FROM billing.UserSubscriptions s
    JOIN billing.Plans p ON p.PlanId = s.PlanId
    WHERE s.UserId = @UserId AND s.Status = N'active' AND p.Code = N'free'
);
DECLARE @ActivePaidCount INT = @ActiveCount - @ActiveFreeCount;
DECLARE @OpenPurchaseCount INT = (SELECT COUNT(*) FROM #OpenSubscriptionPurchases);
DECLARE @HasTeacherRole BIT = CASE
    WHEN @TeacherRoleId IS NOT NULL AND EXISTS (
        SELECT 1 FROM core.UserRoles
        WHERE UserId = @UserId AND RoleId = @TeacherRoleId
    ) THEN 1 ELSE 0
END;

PRINT N'';
PRINT N'=== Qué se haría ===';
PRINT N'Active totales: ' + CAST(@ActiveCount AS NVARCHAR(20))
    + N' (free=' + CAST(@ActiveFreeCount AS NVARCHAR(20))
    + N', paid=' + CAST(@ActivePaidCount AS NVARCHAR(20)) + N')';
PRINT N'Purchases subscription abiertas (pending/awaiting_payment): '
    + CAST(@OpenPurchaseCount AS NVARCHAR(20));
PRINT N'Rol teacher: ' + CASE WHEN @HasTeacherRole = 1 THEN N'sí (se quita)' ELSE N'no' END;
PRINT N'Se dejaría 1 sola suscripción free active (internal).';

PRINT N'';
PRINT N'=== Purchases que pasarían a cancelled ===';
SELECT
    p.PurchaseId,
    p.ProductCode,
    p.ProviderCode,
    p.ProviderTransactionId,
    p.Status,
    p.BillingCycle,
    p.CreatedAt
FROM billing.Purchases p
INNER JOIN #OpenSubscriptionPurchases ids ON ids.PurchaseId = p.PurchaseId
ORDER BY p.CreatedAt DESC;

IF NOT EXISTS (SELECT 1 FROM #OpenSubscriptionPurchases)
    PRINT N'(Ninguna purchase de suscripción abierta.)';

PRINT N'';
PRINT N'=== IDs de proveedor a cancelar FUERA de CraftQuest ===';
SELECT
    PlanCode,
    Status,
    ProviderCode,
    ProviderSubscriptionId,
    BillingCycle,
    StartedAt,
    EndsAt
FROM #PaidProviderIds
ORDER BY StartedAt DESC;

IF NOT EXISTS (SELECT 1 FROM #PaidProviderIds)
    PRINT N'(No hay ProviderSubscriptionId de pago en BD para este usuario.)';

DECLARE @Applied BIT = 0;
DECLARE @CancelledPurchases INT = 0;

IF @DryRun = 1
BEGIN
    PRINT N'';
    PRINT N'DryRun: no se escribió nada. Pon @DryRun = 0 para aplicar.';
END
ELSE
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE billing.UserSubscriptions
        SET Status = N'cancelled',
            EndsAt = @Now,
            AutoRenewEnabled = 0,
            CancelAtPeriodEnd = 0,
            PaymentIssuePending = 0
        WHERE UserId = @UserId
          AND Status = N'active';

        INSERT INTO billing.UserSubscriptions (
            UserSubscriptionId,
            UserId,
            PlanId,
            Status,
            StartedAt,
            EndsAt,
            ProviderCode,
            ProviderSubscriptionId,
            BillingCycle,
            AutoRenewEnabled,
            CancelAtPeriodEnd,
            LastPaymentAt,
            PaymentIssuePending,
            CreatedAt)
        VALUES (
            NEWID(),
            @UserId,
            @FreePlanId,
            N'active',
            @Now,
            NULL,
            N'internal',
            NULL,
            N'monthly',
            0,
            0,
            NULL,
            0,
            @Now);

        UPDATE p
        SET p.Status = N'cancelled'
        FROM billing.Purchases p
        INNER JOIN #OpenSubscriptionPurchases ids ON ids.PurchaseId = p.PurchaseId
        WHERE p.UserId = @UserId
          AND p.ProductType = N'subscription'
          AND p.Status IN (N'pending', N'awaiting_payment');

        SET @CancelledPurchases = @@ROWCOUNT;

        IF @TeacherRoleId IS NOT NULL
            DELETE FROM core.UserRoles
            WHERE UserId = @UserId AND RoleId = @TeacherRoleId;

        COMMIT TRANSACTION;
        SET @Applied = 1;

        PRINT N'';
        PRINT N'Aplicado.';
        PRINT N'Purchases de suscripción canceladas: ' + CAST(@CancelledPurchases AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSev INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();
        RAISERROR(@ErrMsg, @ErrSev, @ErrState);
    END CATCH;
END;

IF @Applied = 1
BEGIN
    PRINT N'';
    PRINT N'=== Estado actual del usuario ===';

    SELECT
        u.Email,
        u.UserId,
        p.Code AS PlanCode,
        p.Name AS PlanName,
        s.Status,
        s.StartedAt,
        s.ProviderCode,
        s.AutoRenewEnabled,
        s.PaymentIssuePending,
        ISNULL((
            SELECT SUM(cl.Delta)
            FROM billing.CreditLedger cl
            WHERE cl.UserId = u.UserId AND cl.CreditType = N'ai'
        ), 0) AS AiPlanCreditsBalance,
        ISNULL((
            SELECT SUM(cl.Delta)
            FROM billing.CreditLedger cl
            WHERE cl.UserId = u.UserId AND cl.CreditType = N'ai_purchased'
        ), 0) AS AiPurchasedCreditsBalance,
        STRING_AGG(r.Code, N', ') WITHIN GROUP (ORDER BY r.Code) AS Roles
    FROM core.Users u
    JOIN billing.UserSubscriptions s
        ON s.UserId = u.UserId AND s.Status = N'active'
    JOIN billing.Plans p ON p.PlanId = s.PlanId
    LEFT JOIN core.UserRoles ur ON ur.UserId = u.UserId
    LEFT JOIN core.Roles r ON r.RoleId = ur.RoleId
    WHERE u.UserId = @UserId
    GROUP BY
        u.Email, u.UserId, p.Code, p.Name, s.Status, s.StartedAt, s.ProviderCode,
        s.AutoRenewEnabled, s.PaymentIssuePending;

    PRINT N'';
    PRINT N'Recuerda cancelar en el proveedor las filas listadas arriba (PayPal / Play / App Store).';
END;

DROP TABLE IF EXISTS #PaidProviderIds;
DROP TABLE IF EXISTS #OpenSubscriptionPurchases;

GO
