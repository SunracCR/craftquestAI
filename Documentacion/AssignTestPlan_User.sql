/* Plan de pruebas + asignación a un usuario por email.
   Ajusta @Email antes de ejecutar. Requiere QUOTED_IDENTIFIER ON para MERGE/índices. */

SET QUOTED_IDENTIFIER ON;
GO

DECLARE @Email NVARCHAR(320) = N'carlossm01@gmail.com';
DECLARE @PlanCode NVARCHAR(40) = N'test';

MERGE billing.Plans AS target
USING (VALUES
    (@PlanCode, N'Test / Dev', NULL, NULL, 100, 100, 500, 50, 0, 0)
) AS source (Code, Name, MonthlyPrice, AnnualPrice, MaxQuizzes, MaxQuestionsPerQuiz, MonthlyAiCredits, MonthlyShareCodes, IsTeacherPlan, IsInstitutionPlan)
ON target.Code = source.Code
WHEN MATCHED THEN UPDATE SET
    Name = source.Name,
    MaxQuizzes = source.MaxQuizzes,
    MaxQuestionsPerQuiz = source.MaxQuestionsPerQuiz,
    MonthlyAiCredits = source.MonthlyAiCredits,
    MonthlyShareCodes = source.MonthlyShareCodes,
    IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (Code, Name, MonthlyPrice, AnnualPrice, MaxQuizzes, MaxQuestionsPerQuiz, MonthlyAiCredits, MonthlyShareCodes, IsTeacherPlan, IsInstitutionPlan, IsActive)
    VALUES (source.Code, source.Name, source.MonthlyPrice, source.AnnualPrice, source.MaxQuizzes, source.MaxQuestionsPerQuiz, source.MonthlyAiCredits, source.MonthlyShareCodes, source.IsTeacherPlan, source.IsInstitutionPlan, 1);
GO

DECLARE @Email NVARCHAR(320) = N'carlossm01@gmail.com';
DECLARE @PlanCode NVARCHAR(40) = N'test';

DECLARE @UserId UNIQUEIDENTIFIER = (
    SELECT TOP (1) UserId
    FROM core.Users
    WHERE Email = @Email AND DeletedAt IS NULL
);

IF @UserId IS NULL
BEGIN
    RAISERROR('Usuario no encontrado: %s', 16, 1, @Email);
    RETURN;
END

DECLARE @PlanId INT = (
    SELECT PlanId FROM billing.Plans WHERE Code = @PlanCode AND IsActive = 1
);

IF @PlanId IS NULL
BEGIN
    RAISERROR('Plan %s no encontrado.', 16, 1, @PlanCode);
    RETURN;
END

DECLARE @Now DATETIME2(7) = SYSUTCDATETIME();

UPDATE billing.UserSubscriptions
SET Status = N'cancelled', EndsAt = @Now
WHERE UserId = @UserId AND Status = N'active';

INSERT INTO billing.UserSubscriptions (
    UserSubscriptionId, UserId, PlanId, Status, StartedAt, ProviderCode, CreatedAt)
VALUES (NEWID(), @UserId, @PlanId, N'active', @Now, N'manual_test', @Now);

/* Créditos IA de prueba vía ledger (ajuste admin hasta balance ~500) */
DECLARE @TargetAiCredits INT = 500;
DECLARE @CurrentAiCredits INT = ISNULL((
    SELECT SUM(Delta)
    FROM billing.CreditLedger
    WHERE UserId = @UserId AND CreditType = N'ai'
), 0);

IF @CurrentAiCredits < @TargetAiCredits
BEGIN
    INSERT INTO billing.CreditLedger (
        CreditLedgerId, UserId, CreditType, Delta, BalanceAfter, Reason, CreatedAt)
    VALUES (
        NEWID(),
        @UserId,
        N'ai',
        @TargetAiCredits - @CurrentAiCredits,
        @TargetAiCredits,
        N'admin_adjustment',
        @Now);
END

SELECT
    u.Email,
    p.Code AS PlanCode,
    p.MaxQuizzes,
    p.MaxQuestionsPerQuiz,
    p.MonthlyAiCredits,
    ISNULL((
        SELECT SUM(Delta)
        FROM billing.CreditLedger cl
        WHERE cl.UserId = u.UserId AND cl.CreditType = N'ai'
    ), 0) AS AiCreditsBalance,
    (SELECT COUNT(*) FROM quiz.Quizzes q WHERE q.CreatedByUserId = u.UserId AND q.DeletedAt IS NULL) AS QuizzesCreated
FROM core.Users u
JOIN billing.UserSubscriptions s ON s.UserId = u.UserId AND s.Status = N'active'
JOIN billing.Plans p ON p.PlanId = s.PlanId
WHERE u.UserId = @UserId;
GO
