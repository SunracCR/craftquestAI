/* Elimina una cuenta de usuario por COMPLETO en CraftQuest (Azure SQL).
 *
 * Ajusta @Email antes de ejecutar.
 *
 * @DryRun = 1 (default): solo muestra conteos; no borra nada.
 * @DryRun = 0: ejecuta la eliminación en una transacción.
 *
 * IMPORTANTE:
 *   - IRREVERSIBLE. Incluye cuestionarios creados, clases como profesor, Prep+ creado,
 *     compras, práctica, referidos, notificaciones, etc.
 *   - NO cancela suscripciones en PayPal / Google Play / App Store; hazlo aparte.
 *   - Otros usuarios pierden acceso a cuestionarios / clases de este usuario.
 *   - No elimina blobs en Azure Storage (PDFs, imágenes); solo filas en BD.
 */

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

DECLARE @Email NVARCHAR(320) = N'tu@email.com';   -- <-- cambiar
DECLARE @DryRun BIT = 1;                          -- 1 = vista previa, 0 = ejecutar

DECLARE @UserId UNIQUEIDENTIFIER = (
    SELECT TOP (1) UserId
    FROM core.Users
    WHERE (Email = @Email OR EmailNormalized = UPPER(LTRIM(RTRIM(@Email))))
      AND DeletedAt IS NULL
);

IF @UserId IS NULL
BEGIN
    RAISERROR(N'Usuario no encontrado (o ya eliminado): %s', 16, 1, @Email);
    RETURN;
END;

/* --- Alcance del usuario --- */
IF OBJECT_ID('tempdb..#ClassIds') IS NOT NULL DROP TABLE #ClassIds;
CREATE TABLE #ClassIds (ClassId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY);

INSERT INTO #ClassIds (ClassId)
SELECT c.ClassId
FROM teacher.Classes c
WHERE c.TeacherUserId = @UserId;

IF OBJECT_ID('tempdb..#QuizIds') IS NOT NULL DROP TABLE #QuizIds;
CREATE TABLE #QuizIds (QuizId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY);

INSERT INTO #QuizIds (QuizId)
SELECT q.QuizId
FROM quiz.Quizzes q
WHERE q.CreatedByUserId = @UserId;

IF OBJECT_ID('tempdb..#AssignmentIds') IS NOT NULL DROP TABLE #AssignmentIds;
CREATE TABLE #AssignmentIds (AssignmentId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY);

INSERT INTO #AssignmentIds (AssignmentId)
SELECT a.AssignmentId
FROM teacher.Assignments a
WHERE a.CreatedByUserId = @UserId
   OR a.ClassId IN (SELECT ClassId FROM #ClassIds);

IF OBJECT_ID('tempdb..#QuestionIds') IS NOT NULL DROP TABLE #QuestionIds;
CREATE TABLE #QuestionIds (QuestionId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY);

INSERT INTO #QuestionIds (QuestionId)
SELECT q.QuestionId
FROM quiz.Questions q
WHERE q.QuizId IN (SELECT QuizId FROM #QuizIds);

IF OBJECT_ID('tempdb..#PrepCatalogItemIds') IS NOT NULL DROP TABLE #PrepCatalogItemIds;
CREATE TABLE #PrepCatalogItemIds (CatalogItemId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY);

IF OBJECT_ID(N'catalog.PrepCatalogItems', N'U') IS NOT NULL
BEGIN
    INSERT INTO #PrepCatalogItemIds (CatalogItemId)
    SELECT i.CatalogItemId
    FROM catalog.PrepCatalogItems i
    WHERE i.CreatedByUserId = @UserId;
END;

IF OBJECT_ID('tempdb..#PracticeSessionIds') IS NOT NULL DROP TABLE #PracticeSessionIds;
CREATE TABLE #PracticeSessionIds (PracticeSessionId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY);

INSERT INTO #PracticeSessionIds (PracticeSessionId)
SELECT ps.PracticeSessionId
FROM practice.PracticeSessions ps
WHERE ps.StudentUserId = @UserId
   OR ps.QuizId IN (SELECT QuizId FROM #QuizIds)
   OR ps.ClassId IN (SELECT ClassId FROM #ClassIds)
   OR ps.AssignmentId IN (SELECT AssignmentId FROM #AssignmentIds);

IF OBJECT_ID('tempdb..#PurchaseIds') IS NOT NULL DROP TABLE #PurchaseIds;
CREATE TABLE #PurchaseIds (PurchaseId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY);

INSERT INTO #PurchaseIds (PurchaseId)
SELECT p.PurchaseId
FROM billing.Purchases p
WHERE p.UserId = @UserId;

DECLARE @QuizCount INT = (SELECT COUNT(*) FROM #QuizIds);
DECLARE @ClassCount INT = (SELECT COUNT(*) FROM #ClassIds);
DECLARE @PrepItemCount INT = (SELECT COUNT(*) FROM #PrepCatalogItemIds);

PRINT N'--- DeleteUserAccount_Complete ---';
PRINT N'Email: ' + @Email;
PRINT N'UserId: ' + CONVERT(NVARCHAR(36), @UserId);
PRINT N'DryRun: ' + CASE WHEN @DryRun = 1 THEN N'SÍ' ELSE N'NO (BORRANDO)' END;
PRINT N'Quizzes del usuario: ' + CAST(@QuizCount AS NVARCHAR(20));
PRINT N'Clases como profesor: ' + CAST(@ClassCount AS NVARCHAR(20));
PRINT N'Ítems Prep+ creados: ' + CAST(@PrepItemCount AS NVARCHAR(20));
PRINT N'';

/* --- Vista previa --- */
IF OBJECT_ID(N'catalog.PrepReferralConversions', N'U') IS NOT NULL
    SELECT N'PrepReferralConversions' AS [Tabla], COUNT(*) AS [Filas]
    FROM catalog.PrepReferralConversions c
    WHERE c.BuyerUserId = @UserId OR c.ReferrerUserId = @UserId
       OR c.CatalogItemId IN (SELECT CatalogItemId FROM #PrepCatalogItemIds);

SELECT N'PracticeSessions (alcance)' AS [Tabla], COUNT(*) AS [Filas] FROM #PracticeSessionIds;
SELECT N'QuizAccesses (usuario o sus quizzes)' AS [Tabla], COUNT(*) AS [Filas]
FROM sharing.QuizAccesses qa
WHERE qa.UserId = @UserId
   OR qa.QuizId IN (SELECT QuizId FROM #QuizIds)
   OR qa.ClassId IN (SELECT ClassId FROM #ClassIds)
   OR qa.AssignmentId IN (SELECT AssignmentId FROM #AssignmentIds);

SELECT N'Quizzes' AS [Tabla], COUNT(*) AS [Filas] FROM #QuizIds;
SELECT N'Questions' AS [Tabla], COUNT(*) AS [Filas] FROM #QuestionIds;
SELECT N'Purchases' AS [Tabla], COUNT(*) AS [Filas] FROM #PurchaseIds;
SELECT N'UserSubscriptions' AS [Tabla], COUNT(*) AS [Filas]
FROM billing.UserSubscriptions s WHERE s.UserId = @UserId;

IF @DryRun = 1
BEGIN
    PRINT N'';
    PRINT N'Sin cambios (DryRun=1). Para borrar: SET @DryRun = 0';
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    /* ===== Prep+ referidos ===== */
    IF OBJECT_ID(N'catalog.PrepReferralConversions', N'U') IS NOT NULL
    BEGIN
        DELETE c
        FROM catalog.PrepReferralConversions c
        WHERE c.BuyerUserId = @UserId
           OR c.ReferrerUserId = @UserId
           OR c.CatalogItemId IN (SELECT CatalogItemId FROM #PrepCatalogItemIds);

        IF COL_LENGTH('billing.Purchases', 'PrepReferralCodeId') IS NOT NULL
        BEGIN
            UPDATE p
            SET p.PrepReferralCodeId = NULL
            FROM billing.Purchases p
            INNER JOIN catalog.PrepReferralCodes r ON r.ReferralCodeId = p.PrepReferralCodeId
            WHERE r.ReferrerUserId = @UserId
               OR r.CatalogItemId IN (SELECT CatalogItemId FROM #PrepCatalogItemIds);
        END;

        DELETE r
        FROM catalog.PrepReferralCodes r
        WHERE r.ReferrerUserId = @UserId
           OR r.CatalogItemId IN (SELECT CatalogItemId FROM #PrepCatalogItemIds);
    END;

    /* ===== Práctica (snapshots → sesiones) ===== */
    DELETE aos
    FROM practice.PracticeAnswerOptionSnapshots aos
    INNER JOIN practice.PracticeQuestionSnapshots pqs ON pqs.PracticeQuestionSnapshotId = aos.PracticeQuestionSnapshotId
    WHERE pqs.PracticeSessionId IN (SELECT PracticeSessionId FROM #PracticeSessionIds);

    DELETE pqs
    FROM practice.PracticeQuestionSnapshots pqs
    WHERE pqs.PracticeSessionId IN (SELECT PracticeSessionId FROM #PracticeSessionIds);

    DELETE ps
    FROM practice.PracticeSessions ps
    WHERE ps.PracticeSessionId IN (SELECT PracticeSessionId FROM #PracticeSessionIds);

    DELETE pref
    FROM practice.UserQuizPracticePreferences pref
    WHERE pref.UserId = @UserId
       OR pref.QuizId IN (SELECT QuizId FROM #QuizIds);

    /* ===== Visitas guest en sus quizzes ===== */
    IF OBJECT_ID(N'guest.GuestVisits', N'U') IS NOT NULL
    BEGIN
        DELETE gv
        FROM guest.GuestVisits gv
        WHERE gv.QuizId IN (SELECT QuizId FROM #QuizIds);
    END;

    /* ===== Accesos y códigos de compartir ===== */
    DELETE qa
    FROM sharing.QuizAccesses qa
    WHERE qa.UserId = @UserId
       OR qa.QuizId IN (SELECT QuizId FROM #QuizIds)
       OR qa.ClassId IN (SELECT ClassId FROM #ClassIds)
       OR qa.AssignmentId IN (SELECT AssignmentId FROM #AssignmentIds);

    DELETE sc
    FROM sharing.ShareCodes sc
    WHERE sc.CreatedByUserId = @UserId
       OR sc.QuizId IN (SELECT QuizId FROM #QuizIds)
       OR sc.AssignmentId IN (SELECT AssignmentId FROM #AssignmentIds);

    /* ===== Clases / tareas ===== */
    DELETE a
    FROM teacher.Assignments a
    WHERE a.AssignmentId IN (SELECT AssignmentId FROM #AssignmentIds);

    DELETE cm
    FROM teacher.ClassMembers cm
    WHERE cm.UserId = @UserId
       OR cm.ClassId IN (SELECT ClassId FROM #ClassIds);

    DELETE c
    FROM teacher.Classes c
    WHERE c.ClassId IN (SELECT ClassId FROM #ClassIds);

    /* ===== Prep+ catálogo creado por el usuario ===== */
    IF OBJECT_ID(N'catalog.PrepCatalogItems', N'U') IS NOT NULL
    BEGIN
        UPDATE qa
        SET qa.PrepCatalogItemId = NULL
        FROM sharing.QuizAccesses qa
        WHERE qa.PrepCatalogItemId IN (SELECT CatalogItemId FROM #PrepCatalogItemIds);

        DELETE i
        FROM catalog.PrepCatalogItems i
        WHERE i.CatalogItemId IN (SELECT CatalogItemId FROM #PrepCatalogItemIds);
    END;

    /* ===== IA e importaciones ===== */
    IF OBJECT_ID(N'ai.AiJobs', N'U') IS NOT NULL
    BEGIN
        DELETE j
        FROM ai.AiJobs j
        WHERE j.RequestedByUserId = @UserId
           OR j.TargetQuizId IN (SELECT QuizId FROM #QuizIds);
    END;

    IF OBJECT_ID(N'importing.QuestionImportErrors', N'U') IS NOT NULL
    BEGIN
        DELETE e
        FROM importing.QuestionImportErrors e
        INNER JOIN importing.QuestionImportBatches b ON b.QuestionImportBatchId = e.QuestionImportBatchId
        WHERE b.UploadedByUserId = @UserId
           OR b.QuizId IN (SELECT QuizId FROM #QuizIds);
    END;

    IF OBJECT_ID(N'importing.QuestionImportRows', N'U') IS NOT NULL
    BEGIN
        DELETE r
        FROM importing.QuestionImportRows r
        INNER JOIN importing.QuestionImportBatches b ON b.QuestionImportBatchId = r.QuestionImportBatchId
        WHERE b.UploadedByUserId = @UserId
           OR b.QuizId IN (SELECT QuizId FROM #QuizIds);
    END;

    IF OBJECT_ID(N'importing.QuestionImportBatches', N'U') IS NOT NULL
    BEGIN
        DELETE b
        FROM importing.QuestionImportBatches b
        WHERE b.UploadedByUserId = @UserId
           OR b.QuizId IN (SELECT QuizId FROM #QuizIds);
    END;

    /* ===== Preguntas de sus cuestionarios ===== */
    IF OBJECT_ID(N'analytics.AnswerOptionStats', N'U') IS NOT NULL
    BEGIN
        DELETE aos
        FROM analytics.AnswerOptionStats aos
        INNER JOIN quiz.QuestionAnswerOptions ao ON ao.AnswerOptionId = aos.AnswerOptionId
        WHERE ao.QuestionId IN (SELECT QuestionId FROM #QuestionIds);
    END;

    IF OBJECT_ID(N'analytics.QuestionStats', N'U') IS NOT NULL
    BEGIN
        DELETE qs
        FROM analytics.QuestionStats qs
        WHERE qs.QuestionId IN (SELECT QuestionId FROM #QuestionIds);
    END;

    DELETE cao
    FROM quiz.QuestionCorrectAnswerOptions cao
    WHERE cao.QuestionId IN (SELECT QuestionId FROM #QuestionIds);

    IF OBJECT_ID(N'quiz.QuestionJustificationSources', N'U') IS NOT NULL
    BEGIN
        DELETE src
        FROM quiz.QuestionJustificationSources src
        INNER JOIN quiz.QuestionJustifications j ON j.QuestionJustificationId = src.QuestionJustificationId
        WHERE j.QuestionId IN (SELECT QuestionId FROM #QuestionIds);
    END;

    UPDATE j
    SET j.ReviewedByUserId = NULL
    FROM quiz.QuestionJustifications j
    WHERE j.ReviewedByUserId = @UserId;

    DELETE j
    FROM quiz.QuestionJustifications j
    WHERE j.QuestionId IN (SELECT QuestionId FROM #QuestionIds);

    DELETE ao
    FROM quiz.QuestionAnswerOptions ao
    WHERE ao.QuestionId IN (SELECT QuestionId FROM #QuestionIds);

    IF OBJECT_ID(N'catalog.PrepSampleQuestions', N'U') IS NOT NULL
    BEGIN
        DELETE s
        FROM catalog.PrepSampleQuestions s
        WHERE s.QuestionId IN (SELECT QuestionId FROM #QuestionIds);
    END;

    DELETE q
    FROM quiz.Questions q
    WHERE q.QuestionId IN (SELECT QuestionId FROM #QuestionIds);

    /* ===== Materiales de estudio ===== */
    IF OBJECT_ID(N'content.StudyMaterials', N'U') IS NOT NULL
    BEGIN
        UPDATE sm
        SET sm.GeneratedQuizId = NULL
        FROM content.StudyMaterials sm
        WHERE sm.GeneratedQuizId IN (SELECT QuizId FROM #QuizIds);

        DELETE sm
        FROM content.StudyMaterials sm
        WHERE sm.UploadedByUserId = @UserId;
    END;

    /* ===== Cuestionarios y carpetas ===== */
    IF COL_LENGTH('quiz.Quizzes', 'FolderId') IS NOT NULL
    BEGIN
        UPDATE q
        SET q.FolderId = NULL
        FROM quiz.Quizzes q
        WHERE q.QuizId IN (SELECT QuizId FROM #QuizIds);
    END;

    DELETE q
    FROM quiz.Quizzes q
    WHERE q.QuizId IN (SELECT QuizId FROM #QuizIds);

    IF OBJECT_ID(N'quiz.QuizFolders', N'U') IS NOT NULL
    BEGIN
        WHILE EXISTS (SELECT 1 FROM quiz.QuizFolders f WHERE f.OwnerUserId = @UserId)
        BEGIN
            DELETE f
            FROM quiz.QuizFolders f
            WHERE f.OwnerUserId = @UserId
              AND NOT EXISTS (
                    SELECT 1 FROM quiz.QuizFolders c
                    WHERE c.ParentFolderId = f.QuizFolderId AND c.OwnerUserId = @UserId);
            IF @@ROWCOUNT = 0 BREAK;
        END;
    END;

    /* ===== Billing ===== */
    DELETE p
    FROM billing.Purchases p
    WHERE p.PurchaseId IN (SELECT PurchaseId FROM #PurchaseIds);

    DELETE s
    FROM billing.UserSubscriptions s
    WHERE s.UserId = @UserId;

    DELETE cl
    FROM billing.CreditLedger cl
    WHERE cl.UserId = @UserId;

    /* ===== Media (tras desvincular imports / materiales) ===== */
    IF OBJECT_ID(N'content.MediaAssets', N'U') IS NOT NULL
    BEGIN
        DELETE m
        FROM content.MediaAssets m
        WHERE m.UploadedByUserId = @UserId;
    END;

    /* ===== Notificaciones y tokens (por si CASCADE no aplica en BD antigua) ===== */
    IF OBJECT_ID(N'core.Notifications', N'U') IS NOT NULL
        DELETE n FROM core.Notifications n WHERE n.UserId = @UserId;

    IF OBJECT_ID(N'core.DeviceTokens', N'U') IS NOT NULL
        DELETE d FROM core.DeviceTokens d WHERE d.UserId = @UserId;

    IF OBJECT_ID(N'core.NotificationPreferences', N'U') IS NOT NULL
        DELETE np FROM core.NotificationPreferences np WHERE np.UserId = @UserId;

    IF OBJECT_ID(N'core.PasswordResetTokens', N'U') IS NOT NULL
        DELETE t FROM core.PasswordResetTokens t WHERE t.UserId = @UserId;

    IF OBJECT_ID(N'core.EmailVerificationTokens', N'U') IS NOT NULL
        DELETE t FROM core.EmailVerificationTokens t WHERE t.UserId = @UserId;

    IF OBJECT_ID(N'core.PasswordChangeTokens', N'U') IS NOT NULL
        DELETE t FROM core.PasswordChangeTokens t WHERE t.UserId = @UserId;

    IF OBJECT_ID(N'core.ParentalConsentTokens', N'U') IS NOT NULL
        DELETE t FROM core.ParentalConsentTokens t WHERE t.UserId = @UserId;

    /* ===== Auth y roles ===== */
    DELETE ur FROM core.UserRoles ur WHERE ur.UserId = @UserId;
    DELETE ap FROM core.AuthProviders ap WHERE ap.UserId = @UserId;

    /* ===== Auditoría (opcional) ===== */
    IF OBJECT_ID(N'audit.AuditEvents', N'U') IS NOT NULL
    BEGIN
        DELETE ae FROM audit.AuditEvents ae WHERE ae.ActorUserId = @UserId;
    END;

    /* ===== Usuario ===== */
    DELETE u FROM core.Users u WHERE u.UserId = @UserId;

    COMMIT TRANSACTION;

    PRINT N'';
    PRINT N'Cuenta eliminada por completo: ' + @Email;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    RAISERROR(@ErrMsg, @ErrSev, @ErrState);
END CATCH;

GO
