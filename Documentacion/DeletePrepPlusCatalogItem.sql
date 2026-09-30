/* Elimina un cuestionario del catálogo Prep+ (un ítem de catalog.PrepCatalogItems).

   El admin solo hace soft-delete (IsDeleted = 1). Este script borra la fila
   del catálogo para que el quiz pueda volver a publicarse en Prep+ si hace falta
   (UQ_PrepCatalogItems_Quiz impide duplicar QuizId mientras exista el ítem).

   Qué se borra:
     - el ítem en catalog.PrepCatalogItems (publicado, borrado lógico o no)
     - ofertas y preguntas de muestra (ON DELETE CASCADE)
     - códigos y conversiones de referido de ese ítem

   Qué se conserva:
     - quiz.Quizzes y sus preguntas
     - compras en billing.Purchases
     - sharing.QuizAccesses (se pone PrepCatalogItemId = NULL)

   Identifica el ítem con UNO de:
     @CatalogItemId | @PrepSlug | @QuizId | @QuizTitle

   @QuizTitle usa LIKE parcial; si hay varios coincidencias, lista y aborta.

   @DryRun = 1 (default): solo muestra qué se borraría.
   @DryRun = 0: ejecuta el DELETE.

   Ejecutar en la base de CraftQuest (SSMS / Azure Data Studio).
*/

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @CatalogItemId UNIQUEIDENTIFIER = NULL;   -- opción A: GUID del ítem Prep+
DECLARE @PrepSlug NVARCHAR(160) = NULL;           -- opción B: slug exacto
DECLARE @QuizId UNIQUEIDENTIFIER = NULL;          -- opción C: GUID del quiz
DECLARE @QuizTitle NVARCHAR(300) = NULL;          -- opción D: título parcial (LIKE)
DECLARE @DryRun BIT = 1;                          -- 1 = vista previa, 0 = ejecutar

IF @CatalogItemId IS NULL
   AND ( @PrepSlug IS NULL OR LTRIM(RTRIM(@PrepSlug)) = N'' )
   AND @QuizId IS NULL
   AND ( @QuizTitle IS NULL OR LTRIM(RTRIM(@QuizTitle)) = N'' )
BEGIN
    RAISERROR(N'Indica @CatalogItemId, @PrepSlug, @QuizId o @QuizTitle.', 16, 1);
    RETURN;
END;

IF @CatalogItemId IS NULL AND @PrepSlug IS NOT NULL AND LTRIM(RTRIM(@PrepSlug)) <> N''
BEGIN
    DECLARE @SlugMatches INT = (
        SELECT COUNT(*)
        FROM catalog.PrepCatalogItems i
        WHERE i.Slug = LOWER(LTRIM(RTRIM(@PrepSlug)))
    );

    IF @SlugMatches = 0
    BEGIN
        RAISERROR(N'No hay ítem Prep+ con ese slug.', 16, 1);
        RETURN;
    END;

    IF @SlugMatches > 1
    BEGIN
        SELECT
            i.CatalogItemId,
            i.Slug,
            COALESCE(i.TitleOverride, q.Title) AS Titulo,
            i.IsPublished,
            i.IsDeleted,
            i.QuizId
        FROM catalog.PrepCatalogItems i
        INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId
        WHERE i.Slug = LOWER(LTRIM(RTRIM(@PrepSlug)))
        ORDER BY i.CreatedAt DESC;

        RAISERROR(N'Hay varios ítems con ese slug. Usa @CatalogItemId.', 16, 1);
        RETURN;
    END;

    SELECT @CatalogItemId = i.CatalogItemId
    FROM catalog.PrepCatalogItems i
    WHERE i.Slug = LOWER(LTRIM(RTRIM(@PrepSlug)));
END;

IF @CatalogItemId IS NULL AND @QuizId IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM quiz.Quizzes WHERE QuizId = @QuizId)
    BEGIN
        RAISERROR(N'No existe ese QuizId en quiz.Quizzes.', 16, 1);
        RETURN;
    END;

    DECLARE @QuizMatches INT = (
        SELECT COUNT(*)
        FROM catalog.PrepCatalogItems i
        WHERE i.QuizId = @QuizId
    );

    IF @QuizMatches = 0
    BEGIN
        RAISERROR(N'Ese quiz no está en el catálogo Prep+.', 16, 1);
        RETURN;
    END;

    IF @QuizMatches > 1
    BEGIN
        SELECT
            i.CatalogItemId,
            i.Slug,
            COALESCE(i.TitleOverride, q.Title) AS Titulo,
            i.IsPublished,
            i.IsDeleted,
            i.QuizId
        FROM catalog.PrepCatalogItems i
        INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId
        WHERE i.QuizId = @QuizId
        ORDER BY i.CreatedAt DESC;

        RAISERROR(N'Hay varios ítems para ese QuizId. Usa @CatalogItemId.', 16, 1);
        RETURN;
    END;

    SELECT @CatalogItemId = i.CatalogItemId
    FROM catalog.PrepCatalogItems i
    WHERE i.QuizId = @QuizId;
END;

IF @CatalogItemId IS NULL AND @QuizTitle IS NOT NULL AND LTRIM(RTRIM(@QuizTitle)) <> N''
BEGIN
    DECLARE @TitleMatches INT = (
        SELECT COUNT(*)
        FROM catalog.PrepCatalogItems i
        INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId
        WHERE i.TitleOverride LIKE N'%' + LTRIM(RTRIM(@QuizTitle)) + N'%'
           OR q.Title LIKE N'%' + LTRIM(RTRIM(@QuizTitle)) + N'%'
    );

    IF @TitleMatches = 0
    BEGIN
        RAISERROR(N'No hay ítem Prep+ con ese título.', 16, 1);
        RETURN;
    END;

    IF @TitleMatches > 1
    BEGIN
        SELECT
            i.CatalogItemId,
            i.Slug,
            COALESCE(i.TitleOverride, q.Title) AS Titulo,
            c.Name AS Categoria,
            i.IsPublished,
            i.IsDeleted,
            i.QuizId,
            i.CreatedAt
        FROM catalog.PrepCatalogItems i
        INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId
        INNER JOIN catalog.PrepCategories c ON c.CategoryId = i.CategoryId
        WHERE i.TitleOverride LIKE N'%' + LTRIM(RTRIM(@QuizTitle)) + N'%'
           OR q.Title LIKE N'%' + LTRIM(RTRIM(@QuizTitle)) + N'%'
        ORDER BY i.CreatedAt DESC;

        RAISERROR(N'Hay varios ítems con ese título. Usa @CatalogItemId.', 16, 1);
        RETURN;
    END;

    SELECT @CatalogItemId = i.CatalogItemId
    FROM catalog.PrepCatalogItems i
    INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId
    WHERE i.TitleOverride LIKE N'%' + LTRIM(RTRIM(@QuizTitle)) + N'%'
       OR q.Title LIKE N'%' + LTRIM(RTRIM(@QuizTitle)) + N'%';
END;

IF NOT EXISTS (SELECT 1 FROM catalog.PrepCatalogItems WHERE CatalogItemId = @CatalogItemId)
BEGIN
    RAISERROR(N'Ítem Prep+ no encontrado.', 16, 1);
    RETURN;
END;

DECLARE @ResolvedQuizId UNIQUEIDENTIFIER;
DECLARE @ItemTitle NVARCHAR(300);
DECLARE @ItemSlug NVARCHAR(160);
DECLARE @CategoryName NVARCHAR(120);
DECLARE @IsPublished BIT;
DECLARE @IsDeleted BIT;

SELECT
    @ResolvedQuizId = i.QuizId,
    @ItemTitle = COALESCE(i.TitleOverride, q.Title),
    @ItemSlug = i.Slug,
    @CategoryName = c.Name,
    @IsPublished = i.IsPublished,
    @IsDeleted = i.IsDeleted
FROM catalog.PrepCatalogItems i
INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId
INNER JOIN catalog.PrepCategories c ON c.CategoryId = i.CategoryId
WHERE i.CatalogItemId = @CatalogItemId;

PRINT N'--- DeletePrepPlusCatalogItem ---';
PRINT N'CatalogItemId: ' + CONVERT(NVARCHAR(36), @CatalogItemId);
PRINT N'Título: ' + ISNULL(@ItemTitle, N'?');
PRINT N'Slug: ' + ISNULL(@ItemSlug, N'(null)');
PRINT N'Categoría: ' + ISNULL(@CategoryName, N'?');
PRINT N'QuizId: ' + CONVERT(NVARCHAR(36), @ResolvedQuizId);
PRINT N'Publicado: ' + CASE WHEN @IsPublished = 1 THEN N'SÍ' ELSE N'NO' END;
PRINT N'Borrado lógico (admin): ' + CASE WHEN @IsDeleted = 1 THEN N'SÍ' ELSE N'NO' END;
PRINT N'DryRun: ' + CASE WHEN @DryRun = 1 THEN N'SÍ (solo vista previa)' ELSE N'NO (ejecutando)' END;
PRINT N'';

SELECT
    i.CatalogItemId,
    i.CategoryId,
    c.Name AS CategoryName,
    i.Slug,
    COALESCE(i.TitleOverride, q.Title) AS Titulo,
    i.IsPublished,
    i.IsDeleted,
    i.QuizId,
    i.CreatedAt
FROM catalog.PrepCatalogItems i
INNER JOIN catalog.PrepCategories c ON c.CategoryId = i.CategoryId
INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId
WHERE i.CatalogItemId = @CatalogItemId;

SELECT N'Ofertas' AS Dependencia, COUNT(*) AS Filas
FROM catalog.PrepAccessOffers o
WHERE o.CatalogItemId = @CatalogItemId;

SELECT N'Preguntas de muestra' AS Dependencia, COUNT(*) AS Filas
FROM catalog.PrepSampleQuestions s
WHERE s.CatalogItemId = @CatalogItemId;

IF OBJECT_ID(N'catalog.PrepReferralCodes', N'U') IS NOT NULL
    SELECT N'Códigos de referido' AS Dependencia, COUNT(*) AS Filas
    FROM catalog.PrepReferralCodes r
    WHERE r.CatalogItemId = @CatalogItemId;

IF OBJECT_ID(N'catalog.PrepReferralConversions', N'U') IS NOT NULL
    SELECT N'Conversiones de referido' AS Dependencia, COUNT(*) AS Filas
    FROM catalog.PrepReferralConversions c
    WHERE c.CatalogItemId = @CatalogItemId;

IF COL_LENGTH('sharing.QuizAccesses', 'PrepCatalogItemId') IS NOT NULL
    SELECT N'Accesos vinculados (se desvincularán)' AS Dependencia, COUNT(*) AS Filas
    FROM sharing.QuizAccesses qa
    WHERE qa.PrepCatalogItemId = @CatalogItemId;

IF @DryRun = 1
BEGIN
    PRINT N'';
    PRINT N'Sin cambios (DryRun=1). Para aplicar: SET @DryRun = 0';
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'catalog.PrepReferralConversions', N'U') IS NOT NULL
    BEGIN
        DELETE c
        FROM catalog.PrepReferralConversions c
        WHERE c.CatalogItemId = @CatalogItemId;
    END;

    IF COL_LENGTH('billing.Purchases', 'PrepReferralCodeId') IS NOT NULL
       AND OBJECT_ID(N'catalog.PrepReferralCodes', N'U') IS NOT NULL
    BEGIN
        UPDATE p
        SET p.PrepReferralCodeId = NULL
        FROM billing.Purchases p
        INNER JOIN catalog.PrepReferralCodes r ON r.ReferralCodeId = p.PrepReferralCodeId
        WHERE r.CatalogItemId = @CatalogItemId;
    END;

    IF OBJECT_ID(N'catalog.PrepReferralCodes', N'U') IS NOT NULL
    BEGIN
        DELETE r
        FROM catalog.PrepReferralCodes r
        WHERE r.CatalogItemId = @CatalogItemId;
    END;

    IF COL_LENGTH('sharing.QuizAccesses', 'PrepCatalogItemId') IS NOT NULL
    BEGIN
        UPDATE qa
        SET qa.PrepCatalogItemId = NULL
        FROM sharing.QuizAccesses qa
        WHERE qa.PrepCatalogItemId = @CatalogItemId;
    END;

    /* Ofertas y muestras se eliminan por ON DELETE CASCADE. */
    DELETE i
    FROM catalog.PrepCatalogItems i
    WHERE i.CatalogItemId = @CatalogItemId;

    IF EXISTS (SELECT 1 FROM catalog.PrepCatalogItems WHERE CatalogItemId = @CatalogItemId)
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR(N'No se pudo eliminar el ítem del catálogo.', 16, 1);
        RETURN;
    END;

    COMMIT TRANSACTION;
    PRINT N'Ítem Prep+ eliminado. El quiz en quiz.Quizzes se conserva.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;
