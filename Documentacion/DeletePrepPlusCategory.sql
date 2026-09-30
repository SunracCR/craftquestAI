/* Elimina una categoría Prep+ y toda su rama, aunque tenga cuestionarios
   publicados en el catálogo.

   El admin rechaza ese borrado (CategoryHasItems). Este script lo hace en
   la base: desvincula dependencias, borra los ítems de catálogo y luego
   las categorías de hoja hacia la raíz.

   Qué se borra:
     - la categoría indicada y sus subcategorías
     - ítems de catalog.PrepCatalogItems de esa rama (publicados o no)
     - ofertas y preguntas de muestra (ON DELETE CASCADE)
     - códigos y conversiones de referido de esos ítems

   Qué se conserva:
     - quiz.Quizzes y sus preguntas (el cuestionario sigue existiendo)
     - compras en billing.Purchases
     - sharing.QuizAccesses (se pone PrepCatalogItemId = NULL)

   Identifica la categoría con UNO de:
     @CategoryId | @Slug | @Name

   @DryRun = 1 (default): solo muestra qué se borraría.
   @DryRun = 0: ejecuta el DELETE.

   Ejecutar en la base de CraftQuest (SSMS / Azure Data Studio).
*/

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @CategoryId UNIQUEIDENTIFIER = NULL;   -- opción A: GUID de la categoría
DECLARE @Slug NVARCHAR(80) = NULL;             -- opción B: slug exacto
DECLARE @Name NVARCHAR(120) = NULL;            -- opción C: nombre exacto
DECLARE @DryRun BIT = 1;                       -- 1 = vista previa, 0 = ejecutar

IF @CategoryId IS NULL
   AND ( @Slug IS NULL OR LTRIM(RTRIM(@Slug)) = N'' )
   AND ( @Name IS NULL OR LTRIM(RTRIM(@Name)) = N'' )
BEGIN
    RAISERROR(N'Indica @CategoryId, @Slug o @Name.', 16, 1);
    RETURN;
END;

IF @CategoryId IS NULL AND @Slug IS NOT NULL AND LTRIM(RTRIM(@Slug)) <> N''
BEGIN
    DECLARE @SlugMatches INT = (
        SELECT COUNT(*)
        FROM catalog.PrepCategories
        WHERE Slug = LOWER(LTRIM(RTRIM(@Slug)))
    );

    IF @SlugMatches = 0
    BEGIN
        RAISERROR(N'No hay categoría con ese slug.', 16, 1);
        RETURN;
    END;

    IF @SlugMatches > 1
    BEGIN
        SELECT CategoryId, ParentCategoryId, Slug, Name, CategoryType
        FROM catalog.PrepCategories
        WHERE Slug = LOWER(LTRIM(RTRIM(@Slug)))
        ORDER BY ParentCategoryId, Name;

        RAISERROR(N'Hay varias categorías con ese slug. Usa @CategoryId.', 16, 1);
        RETURN;
    END;

    SELECT @CategoryId = CategoryId
    FROM catalog.PrepCategories
    WHERE Slug = LOWER(LTRIM(RTRIM(@Slug)));
END;

IF @CategoryId IS NULL AND @Name IS NOT NULL AND LTRIM(RTRIM(@Name)) <> N''
BEGIN
    DECLARE @NameMatches INT = (
        SELECT COUNT(*)
        FROM catalog.PrepCategories
        WHERE Name = LTRIM(RTRIM(@Name))
    );

    IF @NameMatches = 0
    BEGIN
        RAISERROR(N'No hay categoría con ese nombre.', 16, 1);
        RETURN;
    END;

    IF @NameMatches > 1
    BEGIN
        SELECT CategoryId, ParentCategoryId, Slug, Name, CategoryType
        FROM catalog.PrepCategories
        WHERE Name = LTRIM(RTRIM(@Name))
        ORDER BY ParentCategoryId, Name;

        RAISERROR(N'Hay varias categorías con ese nombre. Usa @CategoryId.', 16, 1);
        RETURN;
    END;

    SELECT @CategoryId = CategoryId
    FROM catalog.PrepCategories
    WHERE Name = LTRIM(RTRIM(@Name));
END;

IF NOT EXISTS (SELECT 1 FROM catalog.PrepCategories WHERE CategoryId = @CategoryId)
BEGIN
    RAISERROR(N'Categoría no encontrada.', 16, 1);
    RETURN;
END;

IF OBJECT_ID('tempdb..#CategoryIds') IS NOT NULL DROP TABLE #CategoryIds;
CREATE TABLE #CategoryIds (
    CategoryId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    Nivel INT NOT NULL
);

;WITH Rama AS (
    SELECT CategoryId, 0 AS Nivel
    FROM catalog.PrepCategories
    WHERE CategoryId = @CategoryId
    UNION ALL
    SELECT c.CategoryId, r.Nivel + 1
    FROM catalog.PrepCategories c
    INNER JOIN Rama r ON c.ParentCategoryId = r.CategoryId
)
INSERT INTO #CategoryIds (CategoryId, Nivel)
SELECT CategoryId, Nivel
FROM Rama
OPTION (MAXRECURSION 100);

IF OBJECT_ID('tempdb..#CatalogItemIds') IS NOT NULL DROP TABLE #CatalogItemIds;
CREATE TABLE #CatalogItemIds (CatalogItemId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY);

INSERT INTO #CatalogItemIds (CatalogItemId)
SELECT i.CatalogItemId
FROM catalog.PrepCatalogItems i
WHERE i.CategoryId IN (SELECT CategoryId FROM #CategoryIds);

DECLARE @CategoryCount INT = (SELECT COUNT(*) FROM #CategoryIds);
DECLARE @ItemCount INT = (SELECT COUNT(*) FROM #CatalogItemIds);

PRINT N'--- DeletePrepPlusCategory ---';
PRINT N'CategoryId raíz: ' + CONVERT(NVARCHAR(36), @CategoryId);
PRINT N'Categorías en la rama: ' + CAST(@CategoryCount AS NVARCHAR(20));
PRINT N'Ítems de catálogo: ' + CAST(@ItemCount AS NVARCHAR(20));
PRINT N'DryRun: ' + CASE WHEN @DryRun = 1 THEN N'SÍ (solo vista previa)' ELSE N'NO (ejecutando)' END;
PRINT N'';

SELECT
    c.CategoryId,
    c.ParentCategoryId,
    ids.Nivel,
    c.CategoryType,
    c.Slug,
    c.Name,
    c.IsActive
FROM catalog.PrepCategories c
INNER JOIN #CategoryIds ids ON ids.CategoryId = c.CategoryId
ORDER BY ids.Nivel, c.SortOrder, c.Name;

SELECT
    i.CatalogItemId,
    i.CategoryId,
    c.Name AS CategoryName,
    i.Slug,
    COALESCE(i.TitleOverride, q.Title) AS Titulo,
    i.IsPublished,
    i.IsDeleted,
    q.QuizId
FROM catalog.PrepCatalogItems i
INNER JOIN #CatalogItemIds ids ON ids.CatalogItemId = i.CatalogItemId
INNER JOIN catalog.PrepCategories c ON c.CategoryId = i.CategoryId
INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId
ORDER BY c.Name, Titulo;

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
        WHERE c.CatalogItemId IN (SELECT CatalogItemId FROM #CatalogItemIds);

        IF COL_LENGTH('billing.Purchases', 'PrepReferralCodeId') IS NOT NULL
           AND OBJECT_ID(N'catalog.PrepReferralCodes', N'U') IS NOT NULL
        BEGIN
            UPDATE p
            SET p.PrepReferralCodeId = NULL
            FROM billing.Purchases p
            INNER JOIN catalog.PrepReferralCodes r ON r.ReferralCodeId = p.PrepReferralCodeId
            WHERE r.CatalogItemId IN (SELECT CatalogItemId FROM #CatalogItemIds);
        END;

        IF OBJECT_ID(N'catalog.PrepReferralCodes', N'U') IS NOT NULL
        BEGIN
            DELETE r
            FROM catalog.PrepReferralCodes r
            WHERE r.CatalogItemId IN (SELECT CatalogItemId FROM #CatalogItemIds);
        END;
    END;

    IF COL_LENGTH('sharing.QuizAccesses', 'PrepCatalogItemId') IS NOT NULL
    BEGIN
        UPDATE qa
        SET qa.PrepCatalogItemId = NULL
        FROM sharing.QuizAccesses qa
        WHERE qa.PrepCatalogItemId IN (SELECT CatalogItemId FROM #CatalogItemIds);
    END;

    /* Ofertas y muestras se eliminan por ON DELETE CASCADE. */
    DELETE i
    FROM catalog.PrepCatalogItems i
    WHERE i.CatalogItemId IN (SELECT CatalogItemId FROM #CatalogItemIds);

    DECLARE @Filas INT = 1;

    WHILE @Filas > 0
    BEGIN
        DELETE c
        FROM catalog.PrepCategories c
        INNER JOIN #CategoryIds ids ON ids.CategoryId = c.CategoryId
        WHERE NOT EXISTS (
            SELECT 1
            FROM catalog.PrepCategories hijo
            WHERE hijo.ParentCategoryId = c.CategoryId
        );

        SET @Filas = @@ROWCOUNT;
    END;

    IF EXISTS (
        SELECT 1
        FROM catalog.PrepCategories c
        INNER JOIN #CategoryIds ids ON ids.CategoryId = c.CategoryId
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR(N'Quedaron categorías de la rama. Revisa la jerarquía.', 16, 1);
        RETURN;
    END;

    COMMIT TRANSACTION;
    PRINT N'Categoría y cuestionarios de catálogo eliminados. Los quizzes en quiz.Quizzes se conservan.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;
