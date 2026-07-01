/* Asigna un plan de billing a un usuario por email (re-ejecutable).
 *
 * Ajusta @Email y @PlanCode antes de ejecutar.
 * Planes habituales: free | pro | teacher | institution | test
 *
 * Qué hace:
 *   1. Cancela suscripciones activas del usuario.
 *   2. Inserta una nueva fila active en billing.UserSubscriptions.
 *   3. Si el plan es teacher, asigna rol core.Roles 'teacher' (si falta).
 *   4. Opcional: ajusta créditos IA al MonthlyAiCredits del plan (@GrantPlanAiCredits = 1).
 *
 * Nota: para crear/actualizar el plan "test" con límites altos, usa AssignTestPlan_User.sql
 */

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

DECLARE @Email NVARCHAR(320) = N'tu@email.com';      -- <-- cambiar
DECLARE @PlanCode NVARCHAR(40) = N'pro';             -- <-- free | pro | teacher | ...
DECLARE @GrantPlanAiCredits BIT = 1;                 -- 1 = poner balance IA al del plan
DECLARE @ProviderCode NVARCHAR(50) = N'manual_admin';

DECLARE @UserId UNIQUEIDENTIFIER = (
    SELECT TOP (1) UserId
    FROM core.Users
    WHERE (Email = @Email OR EmailNormalized = UPPER(@Email))
      AND DeletedAt IS NULL
);

IF @UserId IS NULL
BEGIN
    RAISERROR(N'Usuario no encontrado: %s', 16, 1, @Email);
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
    RAISERROR(N'Plan no encontrado o inactivo: %s. Revisa billing.Plans o el seed del DDL.', 16, 1, @PlanCode);
    RETURN;
END;

DECLARE @Now DATETIME2(7) = SYSUTCDATETIME();

BEGIN TRANSACTION;

UPDATE billing.UserSubscriptions
SET Status = N'cancelled',
    EndsAt = @Now
WHERE UserId = @UserId
  AND Status = N'active';

DECLARE @BillingCycle NVARCHAR(20) = CASE
    WHEN @PlanCode IN (N'institution') THEN N'monthly'
    ELSE N'monthly'
END;
DECLARE @PeriodEnd DATETIME2(7) = CASE
    WHEN @BillingCycle = N'annual' THEN DATEADD(YEAR, 1, @Now)
    ELSE DATEADD(MONTH, 1, @Now)
END;

INSERT INTO billing.UserSubscriptions (
    UserSubscriptionId,
    UserId,
    PlanId,
    Status,
    StartedAt,
    EndsAt,
    ProviderCode,
    BillingCycle,
    AutoRenewEnabled,
    CancelAtPeriodEnd,
    LastPaymentAt,
    CreatedAt)
VALUES (
    NEWID(),
    @UserId,
    @PlanId,
    N'active',
    @Now,
    CASE WHEN @PlanCode = N'free' THEN NULL ELSE @PeriodEnd END,
    @ProviderCode,
    @BillingCycle,
    CASE WHEN @PlanCode = N'free' THEN 0 ELSE 1 END,
    0,
    CASE WHEN @PlanCode = N'free' THEN NULL ELSE @Now END,
    @Now);

/* Rol teacher si el plan lo requiere */
IF @IsTeacherPlan = 1
BEGIN
    DECLARE @TeacherRoleId INT = (
        SELECT RoleId FROM core.Roles WHERE Code = N'teacher'
    );

    IF @TeacherRoleId IS NULL
        RAISERROR(N'Rol teacher no existe en core.Roles.', 16, 1);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM core.UserRoles
        WHERE UserId = @UserId AND RoleId = @TeacherRoleId
    )
        INSERT INTO core.UserRoles (UserId, RoleId) VALUES (@UserId, @TeacherRoleId);
END

/* Créditos IA (opcional) */
IF @GrantPlanAiCredits = 1 AND @MonthlyAiCredits > 0
BEGIN
    DECLARE @CurrentAiCredits INT = ISNULL((
        SELECT SUM(Delta)
        FROM billing.CreditLedger
        WHERE UserId = @UserId AND CreditType = N'ai'
    ), 0);

    IF @CurrentAiCredits <> @MonthlyAiCredits
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
            @MonthlyAiCredits - @CurrentAiCredits,
            @MonthlyAiCredits,
            N'admin_adjustment',
            @Now);
    END
END

COMMIT TRANSACTION;

/* Verificación */
SELECT
    u.Email,
    u.UserId,
    p.Code AS PlanCode,
    p.Name AS PlanName,
    s.Status,
    s.StartedAt,
    s.ProviderCode,
    p.MaxQuizzes,
    p.MaxQuestionsPerQuiz,
    p.MonthlyAiCredits AS PlanMonthlyAiCredits,
    ISNULL((
        SELECT SUM(cl.Delta)
        FROM billing.CreditLedger cl
        WHERE cl.UserId = u.UserId AND cl.CreditType = N'ai'
    ), 0) AS AiCreditsBalance,
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
    p.MaxQuizzes, p.MaxQuestionsPerQuiz, p.MonthlyAiCredits;

GO
