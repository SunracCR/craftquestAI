/* Baja un usuario a plan Free y cancela todas sus suscripciones activas en BD.
 *
 * Ajusta @Email antes de ejecutar.
 *
 * Qué hace:
 *   1. Cancela filas active en billing.UserSubscriptions (status cancelled, fin inmediato).
 *   2. Inserta suscripción active al plan free (ProviderCode = internal).
 *   3. Quita el rol teacher si tenía un plan teacher activo.
 *   4. Opcional: ajusta créditos IA del plan (@ResetPlanAiCredits = 1; no toca ai_purchased).
 *
 * IMPORTANTE — PayPal / tiendas:
 *   Este script solo actualiza CraftQuest. NO cancela cobros en PayPal, Google Play ni App Store.
 *   Al final lista ProviderSubscriptionId de suscripciones de pago canceladas en BD para que
 *   canceles manualmente en PayPal Developer o en la consola de la tienda.
 *
 * Re-ejecutable: si el usuario ya está en free, cancela de nuevo paid activos (si hubiera) y
 * deja una sola suscripción free active.
 */

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

DECLARE @Email NVARCHAR(320) = N'tu@email.com';   -- <-- cambiar
DECLARE @ResetPlanAiCredits BIT = 1;              -- 1 = saldo ai al cupo del plan free

DECLARE @UserId UNIQUEIDENTIFIER = (
    SELECT TOP (1) UserId
    FROM core.Users
    WHERE (Email = @Email OR EmailNormalized = UPPER(@Email))
      AND DeletedAt IS NULL
);

IF @UserId IS NULL
BEGIN
    RAISERROR(N'Usuario no encontrado (o cuenta eliminada): %s', 16, 1, @Email);
    RETURN;
END;

DECLARE @FreePlanId INT;
DECLARE @FreeMonthlyAiCredits INT;

SELECT
    @FreePlanId = PlanId,
    @FreeMonthlyAiCredits = MonthlyAiCredits
FROM billing.Plans
WHERE Code = N'free' AND IsActive = 1;

IF @FreePlanId IS NULL
BEGIN
    RAISERROR(N'Plan free no encontrado en billing.Plans.', 16, 1);
    RETURN;
END;

DECLARE @Now DATETIME2(7) = SYSUTCDATETIME();

/* Suscripciones de pago que se cancelarán (para cancelar también en PayPal/tienda) */
IF OBJECT_ID('tempdb..#PaidSubsToCancel') IS NOT NULL
    DROP TABLE #PaidSubsToCancel;

SELECT
    s.UserSubscriptionId,
    p.Code AS PlanCode,
    s.ProviderCode,
    s.ProviderSubscriptionId,
    s.BillingCycle,
    s.AutoRenewEnabled,
    s.StartedAt,
    s.EndsAt
INTO #PaidSubsToCancel
FROM billing.UserSubscriptions s
JOIN billing.Plans p ON p.PlanId = s.PlanId
WHERE s.UserId = @UserId
  AND s.Status = N'active'
  AND p.Code <> N'free';

DECLARE @HadTeacherPlan BIT = CASE
    WHEN EXISTS (
        SELECT 1
        FROM #PaidSubsToCancel
        WHERE PlanCode = N'teacher'
    ) THEN 1
    ELSE 0
END;

BEGIN TRANSACTION;

/* Cancelar todas las suscripciones activas (free, pro, teacher, etc.) */
UPDATE billing.UserSubscriptions
SET Status = N'cancelled',
    EndsAt = @Now,
    AutoRenewEnabled = 0,
    CancelAtPeriodEnd = 0
WHERE UserId = @UserId
  AND Status = N'active';

/* Nueva suscripción free */
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
    @Now);

/* Quitar rol teacher si venía de plan teacher */
IF @HadTeacherPlan = 1
BEGIN
    DECLARE @TeacherRoleId INT = (
        SELECT RoleId FROM core.Roles WHERE Code = N'teacher'
    );

    IF @TeacherRoleId IS NOT NULL
        DELETE FROM core.UserRoles
        WHERE UserId = @UserId AND RoleId = @TeacherRoleId;
END

/* Créditos IA del plan (solo tipo ai; no toca ai_purchased) */
IF @ResetPlanAiCredits = 1 AND @FreeMonthlyAiCredits >= 0
BEGIN
    DECLARE @CurrentPlanAiCredits INT = ISNULL((
        SELECT SUM(Delta)
        FROM billing.CreditLedger
        WHERE UserId = @UserId AND CreditType = N'ai'
    ), 0);

    IF @CurrentPlanAiCredits <> @FreeMonthlyAiCredits
    BEGIN
        INSERT INTO billing.CreditLedger (
            CreditLedgerId,
            UserId,
            CreditType,
            Delta,
            BalanceAfter,
            Reason,
            CreatedAt)
        VALUES (
            NEWID(),
            @UserId,
            N'ai',
            @FreeMonthlyAiCredits - @CurrentPlanAiCredits,
            @FreeMonthlyAiCredits,
            N'admin_adjustment',
            @Now);
    END
END

COMMIT TRANSACTION;

/* --- Resultados --- */

PRINT N'';
PRINT N'=== Suscripciones de pago canceladas en BD (cancelar también en el proveedor) ===';

SELECT
    PlanCode,
    ProviderCode,
    ProviderSubscriptionId,
    BillingCycle,
    StartedAt AS PreviousStartedAt,
    EndsAt AS CancelledEndsAt
FROM #PaidSubsToCancel
ORDER BY StartedAt DESC;

IF NOT EXISTS (SELECT 1 FROM #PaidSubsToCancel)
    PRINT N'(No había suscripciones de pago activas; solo se normalizó a free.)';

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
    p.MaxQuizzes,
    p.MonthlyAiCredits AS PlanMonthlyAiCredits,
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
    s.AutoRenewEnabled, p.MaxQuizzes, p.MonthlyAiCredits;

DROP TABLE #PaidSubsToCancel;

GO
