/* Quita el acceso Prep+ de un usuario a un cuestionario concreto y limpia datos relacionados.
 *
 * Ajusta los parámetros @Email y UNO de: @CatalogItemId | @PrepSlug | @QuizTitle
 *
 * Qué elimina / limpia (solo para ese usuario + ítem):
 *   - conversiones de referidos (como comprador o referente)
 *   - códigos de referido generados por el usuario para ese ítem
 *   - compras prep_access (billing.Purchases) del usuario para ese ítem
 *   - acceso en sharing.QuizAccesses (PrepCatalogItemId o purchase sin clase/asignación)
 *   - sesiones de práctica libre del quiz (sin ClassId / AssignmentId)
 *   - preferencias de práctica (practice.UserQuizPracticePreferences)
 *
 * NO toca: el ítem del catálogo, ofertas, el quiz ni datos de otros usuarios.
 *
 * @DryRun = 1 (default): solo muestra qué se borraría.
 * @DryRun = 0: ejecuta los DELETE.
 */

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

DECLARE @Email NVARCHAR(320) = N'tu@email.com';           -- <-- cambiar
DECLARE @CatalogItemId UNIQUEIDENTIFIER = NULL;             -- opción A: GUID del ítem Prep+
DECLARE @PrepSlug NVARCHAR(160) = NULL;                     -- opción B: slug, ej. N'mi-cuestionario-abc12345'
DECLARE @QuizTitle NVARCHAR(300) = NULL;                    -- opción C: título aproximado (LIKE)
DECLARE @DryRun BIT = 1;                                     -- 1 = vista previa, 0 = ejecutar

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

IF @CatalogItemId IS NULL
   AND ( @PrepSlug IS NULL OR LTRIM(RTRIM(@PrepSlug)) = N'' )
   AND ( @QuizTitle IS NULL OR LTRIM(RTRIM(@QuizTitle)) = N'' )
BEGIN
    RAISERROR(N'Indica @CatalogItemId, @PrepSlug o @QuizTitle.', 16, 1);
    RETURN;
END;

IF @CatalogItemId IS NULL
BEGIN
    SELECT TOP (1) @CatalogItemId = i.CatalogItemId
    FROM catalog.PrepCatalogItems i
    INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId
    WHERE i.IsDeleted = 0
      AND (
            ( @PrepSlug IS NOT NULL AND LTRIM(RTRIM(@PrepSlug)) <> N''
              AND i.Slug = LOWER(LTRIM(RTRIM(@PrepSlug))) )
         OR ( @QuizTitle IS NOT NULL AND LTRIM(RTRIM(@QuizTitle)) <> N''
              AND ( i.TitleOverride LIKE N'%' + LTRIM(RTRIM(@QuizTitle)) + N'%'
                    OR q.Title LIKE N'%' + LTRIM(RTRIM(@QuizTitle)) + N'%' ) )
          )
    ORDER BY i.CreatedAt DESC;
END;

IF @CatalogItemId IS NULL
BEGIN
    RAISERROR(N'Ítem Prep+ no encontrado con los criterios indicados.', 16, 1);
    RETURN;
END;

DECLARE @QuizId UNIQUEIDENTIFIER;
DECLARE @ItemTitle NVARCHAR(300);
DECLARE @ItemSlug NVARCHAR(160);

SELECT
    @QuizId = i.QuizId,
    @ItemTitle = COALESCE(i.TitleOverride, q.Title),
    @ItemSlug = i.Slug
FROM catalog.PrepCatalogItems i
INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId
WHERE i.CatalogItemId = @CatalogItemId;

IF @QuizId IS NULL
BEGIN
    RAISERROR(
        N'CatalogItemId %s no existe en catalog.PrepCatalogItems.',
        16,
        1,
        CONVERT(NVARCHAR(36), @CatalogItemId));
    RETURN;
END;

DECLARE @ProductCodePrefix NVARCHAR(33) =
    LOWER(REPLACE(CONVERT(NVARCHAR(36), @CatalogItemId), N'-', N'')) + N'|';

PRINT N'--- RemoveUserPrepPlusAccess ---';
PRINT N'Usuario: ' + @Email + N' (' + CONVERT(NVARCHAR(36), @UserId) + N')';
PRINT N'Ítem Prep+: ' + ISNULL(@ItemTitle, N'?') + N' | slug=' + ISNULL(@ItemSlug, N'(null)');
PRINT N'CatalogItemId: ' + CONVERT(NVARCHAR(36), @CatalogItemId);
PRINT N'QuizId: ' + CONVERT(NVARCHAR(36), @QuizId);
PRINT N'DryRun: ' + CASE WHEN @DryRun = 1 THEN N'SÍ (solo vista previa)' ELSE N'NO (ejecutando)' END;
PRINT N'';

/* --- Vista previa --- */
SELECT N'PrepReferralConversions' AS [Tabla], COUNT(*) AS [Filas]
FROM catalog.PrepReferralConversions c
WHERE c.CatalogItemId = @CatalogItemId
  AND (c.BuyerUserId = @UserId OR c.ReferrerUserId = @UserId);

SELECT N'PrepReferralCodes' AS [Tabla], COUNT(*) AS [Filas]
FROM catalog.PrepReferralCodes r
WHERE r.CatalogItemId = @CatalogItemId
  AND r.ReferrerUserId = @UserId;

SELECT N'Purchases (prep_access)' AS [Tabla], COUNT(*) AS [Filas]
FROM billing.Purchases p
WHERE p.UserId = @UserId
  AND p.ProductType = N'prep_access'
  AND (
        p.ProductCode LIKE @ProductCodePrefix + N'%'
        OR UPPER(p.ProductCode) LIKE UPPER(@ProductCodePrefix) + N'%'
      );

SELECT N'QuizAccesses' AS [Tabla], COUNT(*) AS [Filas]
FROM sharing.QuizAccesses qa
WHERE qa.UserId = @UserId
  AND (
        qa.PrepCatalogItemId = @CatalogItemId
        OR (
            qa.QuizId = @QuizId
            AND qa.AccessType = N'purchase'
            AND qa.ClassId IS NULL
            AND qa.AssignmentId IS NULL
        )
      );

SELECT N'PracticeSessions (libre)' AS [Tabla], COUNT(*) AS [Filas]
FROM practice.PracticeSessions ps
WHERE ps.StudentUserId = @UserId
  AND ps.QuizId = @QuizId
  AND ps.ClassId IS NULL
  AND ps.AssignmentId IS NULL;

SELECT N'UserQuizPracticePreferences' AS [Tabla], COUNT(*) AS [Filas]
FROM practice.UserQuizPracticePreferences pref
WHERE pref.UserId = @UserId
  AND pref.QuizId = @QuizId;

IF @DryRun = 1
BEGIN
    PRINT N'';
    PRINT N'Sin cambios (DryRun=1). Para aplicar: SET @DryRun = 0';
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    /* 1. Conversiones de referidos del usuario en este ítem */
    DELETE c
    FROM catalog.PrepReferralConversions c
    WHERE c.CatalogItemId = @CatalogItemId
      AND (c.BuyerUserId = @UserId OR c.ReferrerUserId = @UserId);

    /* 2. Quitar FK de compras hacia códigos de referido del usuario */
    UPDATE p
    SET p.PrepReferralCodeId = NULL
    FROM billing.Purchases p
    INNER JOIN catalog.PrepReferralCodes r ON r.ReferralCodeId = p.PrepReferralCodeId
    WHERE r.ReferrerUserId = @UserId
      AND r.CatalogItemId = @CatalogItemId;

    /* 3. Códigos de referido del usuario para este ítem */
    DELETE r
    FROM catalog.PrepReferralCodes r
    WHERE r.CatalogItemId = @CatalogItemId
      AND r.ReferrerUserId = @UserId;

    /* 4. Snapshots de práctica (hijos → padre) */
    DELETE aos
    FROM practice.PracticeAnswerOptionSnapshots aos
    INNER JOIN practice.PracticeQuestionSnapshots pqs ON pqs.PracticeQuestionSnapshotId = aos.PracticeQuestionSnapshotId
    INNER JOIN practice.PracticeSessions ps ON ps.PracticeSessionId = pqs.PracticeSessionId
    WHERE ps.StudentUserId = @UserId
      AND ps.QuizId = @QuizId
      AND ps.ClassId IS NULL
      AND ps.AssignmentId IS NULL;

    DELETE pqs
    FROM practice.PracticeQuestionSnapshots pqs
    INNER JOIN practice.PracticeSessions ps ON ps.PracticeSessionId = pqs.PracticeSessionId
    WHERE ps.StudentUserId = @UserId
      AND ps.QuizId = @QuizId
      AND ps.ClassId IS NULL
      AND ps.AssignmentId IS NULL;

    DELETE ps
    FROM practice.PracticeSessions ps
    WHERE ps.StudentUserId = @UserId
      AND ps.QuizId = @QuizId
      AND ps.ClassId IS NULL
      AND ps.AssignmentId IS NULL;

    /* 5. Preferencias de práctica del quiz */
    DELETE pref
    FROM practice.UserQuizPracticePreferences pref
    WHERE pref.UserId = @UserId
      AND pref.QuizId = @QuizId;

    /* 6. Acceso Prep+ (antes de borrar compras por GrantedByPurchaseId → SetNull) */
    DELETE qa
    FROM sharing.QuizAccesses qa
    WHERE qa.UserId = @UserId
      AND (
            qa.PrepCatalogItemId = @CatalogItemId
            OR (
                qa.QuizId = @QuizId
                AND qa.AccessType = N'purchase'
                AND qa.ClassId IS NULL
                AND qa.AssignmentId IS NULL
            )
          );

    /* 7. Compras prep_access del usuario para este ítem */
    DELETE p
    FROM billing.Purchases p
    WHERE p.UserId = @UserId
      AND p.ProductType = N'prep_access'
      AND (
            p.ProductCode LIKE @ProductCodePrefix + N'%'
            OR UPPER(p.ProductCode) LIKE UPPER(@ProductCodePrefix) + N'%'
          );

    COMMIT TRANSACTION;

    PRINT N'';
    PRINT N'Limpieza Prep+ completada para el usuario e ítem indicados.';
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
