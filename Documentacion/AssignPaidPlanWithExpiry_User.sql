/* Asigna plan Pro o Tutor (teacher) a uno o más usuarios, con fecha de fin.
 *
 * Ajusta @PlanCode, @ExpiresAtUtc y la lista @Emails.
 * Tutor en la app = Code 'teacher' en billing.Plans.
 *
 * Qué hace:
 *   1. Cancela suscripciones active del usuario.
 *   2. Inserta una suscripción active al plan pedido hasta @ExpiresAtUtc.
 *   3. Sin auto-renew: al vencer, ProcessExpiredSubscriptionsAsync baja a Free.
 *   4. Plan teacher: otorga rol teacher. Plan pro: quita el rol teacher si lo tenía.
 *   5. Opcional: ajusta créditos IA del plan (@GrantPlanAiCredits = 1; no toca ai_purchased).
 *
 * Qué NO hace:
 *   - No cobra ni crea suscripciones en PayPal / Google Play / App Store.
 *   - ProviderCode = manual_admin (no es proveedor recurrente).
 *
 * Re-ejecutable. @ExpiresAtUtc debe ser UTC y posterior a ahora.
 */

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @PlanCode NVARCHAR(40) = N'pro';              -- pro | teacher
DECLARE @ExpiresAtUtc DATETIME2(7) = N'2026-12-31T23:59:59';  -- UTC, fin de acceso
DECLARE @GrantPlanAiCredits BIT = 1;                  -- 1 = saldo ai al cupo del plan
DECLARE @BillingCycle NVARCHAR(20) = NULL;            -- NULL = inferir (annual si >= 10 meses)

DECLARE @Emails TABLE (Email NVARCHAR(320) NOT NULL);
INSERT INTO @Emails (Email) VALUES
    (N'tu@email.com');
    -- (N'otro@email.com'),

IF @PlanCode NOT IN (N'pro', N'teacher')
BEGIN
    RAISERROR(N'@PlanCode debe ser pro o teacher (Tutor). Valor: %s', 16, 1, @PlanCode);
    RETURN;
END;

DECLARE @Now DATETIME2(7) = SYSUTCDATETIME();

IF @ExpiresAtUtc <= @Now
BEGIN
    RAISERROR(N'@ExpiresAtUtc debe ser posterior a UTC ahora (%s).', 16, 1, CONVERT(NVARCHAR(27), @Now, 126));
    RETURN;
END;

DECLARE @PlanId INT;
DECLARE @IsTeacherPlan BIT;
DECLARE @MonthlyAiCredits INT;

SELECT
    @PlanId = PlanId,
    @IsTeacherPlan = IsTeacherPlan,
    @MonthlyAiCredits = MonthlyAiCredits
FROM billing.Plans
WHERE Code = @PlanCode AND IsActive = 1;

IF @PlanId IS NULL
BEGIN
    RAISERROR(N'Plan no encontrado o inactivo: %s.', 16, 1, @PlanCode);
    RETURN;
END;

IF @BillingCycle IS NULL
    SET @BillingCycle = CASE
        WHEN DATEDIFF(MONTH, @Now, @ExpiresAtUtc) >= 10 THEN N'annual'
        ELSE N'monthly'
    END;

IF @BillingCycle NOT IN (N'monthly', N'annual')
BEGIN
    RAISERROR(N'@BillingCycle debe ser monthly o annual.', 16, 1);
    RETURN;
END;

DECLARE @TeacherRoleId INT = (SELECT RoleId FROM core.Roles WHERE Code = N'teacher');

IF @IsTeacherPlan = 1 AND @TeacherRoleId IS NULL
BEGIN
    RAISERROR(N'Rol teacher no existe en core.Roles.', 16, 1);
    RETURN;
END;

DECLARE @Users TABLE (
    Email NVARCHAR(320) NOT NULL,
    UserId UNIQUEIDENTIFIER NOT NULL
);

INSERT INTO @Users (Email, UserId)
SELECT e.Email, u.UserId
FROM @Emails e
INNER JOIN core.Users u
    ON (u.Email = e.Email OR u.EmailNormalized = UPPER(LTRIM(RTRIM(e.Email))))
   AND u.DeletedAt IS NULL;

DECLARE @Missing NVARCHAR(MAX) = (
    SELECT STRING_AGG(e.Email, N', ')
    FROM @Emails e
    WHERE NOT EXISTS (SELECT 1 FROM @Users x WHERE x.Email = e.Email)
);

IF @Missing IS NOT NULL
BEGIN
    RAISERROR(N'Usuario no encontrado (o cuenta eliminada): %s', 16, 1, @Missing);
    RETURN;
END;

PRINT N'--- AssignPaidPlanWithExpiry_User ---';
PRINT N'Plan: ' + @PlanCode;
PRINT N'ExpiresAtUtc: ' + CONVERT(NVARCHAR(27), @ExpiresAtUtc, 126);
PRINT N'BillingCycle: ' + @BillingCycle;
PRINT N'Usuarios: ' + CAST((SELECT COUNT(*) FROM @Users) AS NVARCHAR(20));
PRINT N'';

BEGIN TRANSACTION;

UPDATE s
SET Status = N'cancelled',
    EndsAt = @Now,
    AutoRenewEnabled = 0,
    CancelAtPeriodEnd = 0,
    PaymentIssuePending = 0
FROM billing.UserSubscriptions s
INNER JOIN @Users u ON u.UserId = s.UserId
WHERE s.Status = N'active';

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
SELECT
    NEWID(),
    u.UserId,
    @PlanId,
    N'active',
    @Now,
    @ExpiresAtUtc,
    N'manual_admin',
    NULL,
    @BillingCycle,
    0,
    1,
    @Now,
    0,
    @Now
FROM @Users u;

IF @TeacherRoleId IS NOT NULL AND @IsTeacherPlan = 1
    INSERT INTO core.UserRoles (UserId, RoleId)
    SELECT u.UserId, @TeacherRoleId
    FROM @Users u
    WHERE NOT EXISTS (
        SELECT 1 FROM core.UserRoles ur
        WHERE ur.UserId = u.UserId AND ur.RoleId = @TeacherRoleId
    );

IF @TeacherRoleId IS NOT NULL AND @IsTeacherPlan = 0
    DELETE ur
    FROM core.UserRoles ur
    INNER JOIN @Users u ON u.UserId = ur.UserId
    WHERE ur.RoleId = @TeacherRoleId;

IF @GrantPlanAiCredits = 1 AND @MonthlyAiCredits >= 0
BEGIN
    INSERT INTO billing.CreditLedger (
        CreditLedgerId,
        UserId,
        CreditType,
        Delta,
        BalanceAfter,
        Reason,
        CreatedAt)
    SELECT
        NEWID(),
        u.UserId,
        N'ai',
        @MonthlyAiCredits - ISNULL(bal.CurrentBalance, 0),
        @MonthlyAiCredits,
        N'admin_adjustment',
        @Now
    FROM @Users u
    OUTER APPLY (
        SELECT SUM(cl.Delta) AS CurrentBalance
        FROM billing.CreditLedger cl
        WHERE cl.UserId = u.UserId AND cl.CreditType = N'ai'
    ) bal
    WHERE ISNULL(bal.CurrentBalance, 0) <> @MonthlyAiCredits;
END

COMMIT TRANSACTION;

SELECT
    u.Email,
    u.UserId,
    p.Code AS PlanCode,
    s.Status,
    s.StartedAt,
    s.EndsAt,
    s.BillingCycle,
    s.ProviderCode,
    s.AutoRenewEnabled,
    s.CancelAtPeriodEnd,
    ISNULL((
        SELECT SUM(cl.Delta)
        FROM billing.CreditLedger cl
        WHERE cl.UserId = u.UserId AND cl.CreditType = N'ai'
    ), 0) AS AiPlanCreditsBalance,
    STRING_AGG(r.Code, N', ') WITHIN GROUP (ORDER BY r.Code) AS Roles
FROM @Users tgt
JOIN core.Users u ON u.UserId = tgt.UserId
JOIN billing.UserSubscriptions s
    ON s.UserId = u.UserId AND s.Status = N'active'
JOIN billing.Plans p ON p.PlanId = s.PlanId
LEFT JOIN core.UserRoles ur ON ur.UserId = u.UserId
LEFT JOIN core.Roles r ON r.RoleId = ur.RoleId
GROUP BY
    u.Email, u.UserId, p.Code, s.Status, s.StartedAt, s.EndsAt, s.BillingCycle,
    s.ProviderCode, s.AutoRenewEnabled, s.CancelAtPeriodEnd
ORDER BY u.Email;

GO
