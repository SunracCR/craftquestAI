/* Cuentas demo para App Store Review (re-ejecutable).
 *
 * Usuario revisor (login principal):
 *   Email:    appreview@craftquestai.com
 *   Password: CraftQuest2026!
 *   Plan Pro activo hasta @ProExpiresAtUtc (manual_admin, sin IAP).
 *
 * Usuario desechable (solo grabación de eliminar cuenta):
 *   Email:    delete-demo@craftquestai.com
 *   Password: DeleteDemo2026!
 *   Plan Free.
 *
 * Qué hace:
 *   1. Crea o actualiza ambos usuarios (active + email verificado).
 *   2. Asigna rol student y proveedor email.
 *   3. appreview → Pro + créditos IA del plan.
 *   4. delete-demo → Free + créditos IA del plan free.
 *
 * Qué NO hace:
 *   - No configura Google/Apple Sign-In (el revisor puede usar email/contraseña).
 *   - No crea suscripciones en App Store / Play / PayPal.
 *
 * PasswordHash = PBKDF2-SHA256 (100k iter, 16-byte salt + 32-byte key), mismo algoritmo que la API.
 * Si cambias las contraseñas, regenera los hashes con PasswordHasher.HashPassword en .NET.
 *
 * Ejecutar contra producción: api.craftquestai.com
 */

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @ProExpiresAtUtc DATETIME2(7) = N'2027-12-31T23:59:59';
DECLARE @GrantPlanAiCredits BIT = 1;

DECLARE @SeedUsers TABLE (
    Email NVARCHAR(320) NOT NULL PRIMARY KEY,
    DisplayName NVARCHAR(160) NOT NULL,
    PasswordHash VARBINARY(48) NOT NULL,
    PlanCode NVARCHAR(40) NOT NULL
);

INSERT INTO @SeedUsers (Email, DisplayName, PasswordHash, PlanCode) VALUES
(
    N'appreview@craftquestai.com',
    N'App Review',
    0x1F4930D0FE9D0E31BE69B352477200EDD930A69925DD8E5D0E292B7DA6F62DCC55C288DB0D8AC633A52E82688E977C21,
    N'pro'
),
(
    N'delete-demo@craftquestai.com',
    N'Delete Demo',
    0xBC4A9BE57B4F701E14F0DAAC451E3D537DF71460E4782D3E473054FAB44E29682F54763347730F17393617B99B0D0A27,
    N'free'
);

DECLARE @StudentRoleId INT = (SELECT RoleId FROM core.Roles WHERE Code = N'student');
IF @StudentRoleId IS NULL
BEGIN
    RAISERROR(N'Rol student no existe en core.Roles.', 16, 1);
    RETURN;
END;

DECLARE @FreePlanId INT;
DECLARE @FreeMonthlyAiCredits INT;
DECLARE @ProPlanId INT;
DECLARE @ProMonthlyAiCredits INT;

SELECT @FreePlanId = PlanId, @FreeMonthlyAiCredits = MonthlyAiCredits
FROM billing.Plans WHERE Code = N'free' AND IsActive = 1;

SELECT @ProPlanId = PlanId, @ProMonthlyAiCredits = MonthlyAiCredits
FROM billing.Plans WHERE Code = N'pro' AND IsActive = 1;

IF @FreePlanId IS NULL OR @ProPlanId IS NULL
BEGIN
    RAISERROR(N'Planes free y/o pro no encontrados en billing.Plans.', 16, 1);
    RETURN;
END;

DECLARE @Now DATETIME2(7) = SYSUTCDATETIME();
DECLARE @ResolvedUsers TABLE (
    Email NVARCHAR(320) NOT NULL,
    UserId UNIQUEIDENTIFIER NOT NULL,
    PlanCode NVARCHAR(40) NOT NULL
);

BEGIN TRANSACTION;

/* --- Crear o actualizar usuarios --- */
MERGE core.Users AS target
USING (
    SELECT Email, DisplayName, PasswordHash, PlanCode
    FROM @SeedUsers
) AS source
ON target.EmailNormalized = UPPER(LTRIM(RTRIM(source.Email)))
   AND target.DeletedAt IS NULL
WHEN MATCHED THEN
    UPDATE SET
        DisplayName = source.DisplayName,
        PasswordHash = source.PasswordHash,
        Status = N'active',
        EmailVerifiedAt = COALESCE(target.EmailVerifiedAt, @Now),
        AvatarId = COALESCE(target.AvatarId, N'craft_01'),
        PreferredLanguage = COALESCE(target.PreferredLanguage, N'en'),
        ParentalConsentStatus = COALESCE(target.ParentalConsentStatus, N'not_required'),
        UpdatedAt = @Now
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        UserId,
        Email,
        PasswordHash,
        DisplayName,
        AvatarId,
        PreferredLanguage,
        Status,
        EmailVerifiedAt,
        ParentalConsentStatus,
        CreatedAt)
    VALUES (
        NEWID(),
        source.Email,
        source.PasswordHash,
        source.DisplayName,
        N'craft_01',
        N'en',
        N'active',
        @Now,
        N'not_required',
        @Now);

INSERT INTO @ResolvedUsers (Email, UserId, PlanCode)
SELECT s.Email, u.UserId, s.PlanCode
FROM @SeedUsers s
INNER JOIN core.Users u
    ON u.EmailNormalized = UPPER(LTRIM(RTRIM(s.Email)))
   AND u.DeletedAt IS NULL;

IF (SELECT COUNT(*) FROM @ResolvedUsers) <> (SELECT COUNT(*) FROM @SeedUsers)
BEGIN
    RAISERROR(N'No se pudieron resolver todos los usuarios tras MERGE.', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
END;

/* --- Rol student --- */
INSERT INTO core.UserRoles (UserId, RoleId, CreatedAt)
SELECT ru.UserId, @StudentRoleId, @Now
FROM @ResolvedUsers ru
WHERE NOT EXISTS (
    SELECT 1 FROM core.UserRoles ur
    WHERE ur.UserId = ru.UserId AND ur.RoleId = @StudentRoleId
);

/* --- Proveedor email --- */
INSERT INTO core.AuthProviders (
    AuthProviderId,
    UserId,
    ProviderCode,
    ProviderSubject,
    CreatedAt)
SELECT
    NEWID(),
    ru.UserId,
    N'email',
    UPPER(LTRIM(RTRIM(ru.Email))),
    @Now
FROM @ResolvedUsers ru
WHERE NOT EXISTS (
    SELECT 1 FROM core.AuthProviders ap
    WHERE ap.UserId = ru.UserId
      AND ap.ProviderCode = N'email'
);

/* --- Cancelar suscripciones activas previas --- */
UPDATE s
SET Status = N'cancelled',
    EndsAt = @Now,
    AutoRenewEnabled = 0,
    CancelAtPeriodEnd = 0,
    PaymentIssuePending = 0
FROM billing.UserSubscriptions s
INNER JOIN @ResolvedUsers ru ON ru.UserId = s.UserId
WHERE s.Status = N'active';

/* --- appreview → Pro hasta @ProExpiresAtUtc --- */
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
    ru.UserId,
    @ProPlanId,
    N'active',
    @Now,
    @ProExpiresAtUtc,
    N'manual_admin',
    NULL,
    N'annual',
    0,
    1,
    @Now,
    0,
    @Now
FROM @ResolvedUsers ru
WHERE ru.PlanCode = N'pro';

/* --- delete-demo → Free --- */
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
    ru.UserId,
    @FreePlanId,
    N'active',
    @Now,
    NULL,
    N'manual_admin',
    NULL,
    N'monthly',
    0,
    0,
    NULL,
    0,
    @Now
FROM @ResolvedUsers ru
WHERE ru.PlanCode = N'free';

/* --- Créditos IA al cupo del plan --- */
IF @GrantPlanAiCredits = 1
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
        ru.UserId,
        N'ai',
        targetCredits - ISNULL(bal.CurrentBalance, 0),
        targetCredits,
        N'admin_adjustment',
        @Now
    FROM @ResolvedUsers ru
    CROSS APPLY (
        SELECT CASE ru.PlanCode
            WHEN N'pro' THEN @ProMonthlyAiCredits
            ELSE @FreeMonthlyAiCredits
        END AS targetCredits
    ) tc
    OUTER APPLY (
        SELECT SUM(cl.Delta) AS CurrentBalance
        FROM billing.CreditLedger cl
        WHERE cl.UserId = ru.UserId AND cl.CreditType = N'ai'
    ) bal
    WHERE ISNULL(bal.CurrentBalance, 0) <> tc.targetCredits;
END;

COMMIT TRANSACTION;

PRINT N'--- CreateAppReviewDemoUsers: OK ---';
PRINT N'Reviewer: appreview@craftquestai.com / CraftQuest2026! (Pro until '
    + CONVERT(NVARCHAR(27), @ProExpiresAtUtc, 126) + N' UTC)';
PRINT N'Delete demo: delete-demo@craftquestai.com / DeleteDemo2026! (Free)';
PRINT N'';

SELECT
    u.Email,
    u.UserId,
    u.Status,
    u.EmailVerifiedAt,
    p.Code AS PlanCode,
    s.Status AS SubscriptionStatus,
    s.EndsAt,
    s.ProviderCode,
    ISNULL((
        SELECT SUM(cl.Delta)
        FROM billing.CreditLedger cl
        WHERE cl.UserId = u.UserId AND cl.CreditType = N'ai'
    ), 0) AS AiCreditsBalance,
    STRING_AGG(r.Code, N', ') WITHIN GROUP (ORDER BY r.Code) AS Roles
FROM @ResolvedUsers ru
JOIN core.Users u ON u.UserId = ru.UserId
JOIN billing.UserSubscriptions s
    ON s.UserId = u.UserId AND s.Status = N'active'
JOIN billing.Plans p ON p.PlanId = s.PlanId
LEFT JOIN core.UserRoles ur ON ur.UserId = u.UserId
LEFT JOIN core.Roles r ON r.RoleId = ur.RoleId
GROUP BY
    u.Email, u.UserId, u.Status, u.EmailVerifiedAt,
    p.Code, s.Status, s.EndsAt, s.ProviderCode
ORDER BY u.Email;

GO
