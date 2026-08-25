/* Quita acceso DEFINITIVO (IsLifetimeAccess = 1) Prep+ de un usuario.
 *
 * Parámetros:
 *   @Email              — obligatorio
 *   @CatalogItemId      — opcional; NULL = todos los ítems Prep+ del usuario
 *   @PrepSlug           — opcional; alternativa a @CatalogItemId
 *   @DeletePurchases    — 1 = borra también billing.Purchases prep_access ligadas (recomendado para poder recomprar)
 *   @DryRun             — 1 = solo vista previa, 0 = ejecutar
 *
 * Qué hace:
 *   - Elimina filas en sharing.QuizAccesses con IsLifetimeAccess = 1 y AccessType = purchase
 *     (solo acceso Prep+ libre: sin ClassId / AssignmentId)
 *   - Opcionalmente elimina compras prep_access validated/pending asociadas
 *
 * Qué NO toca:
 *   - Accesos temporales activos o expirados (IsLifetimeAccess = 0)
 *   - Sesiones de práctica, referidos, catálogo ni otros usuarios
 *
 * Nota: si el usuario solo tenía acceso definitivo, dejará de poder practicar ese simulacro
 *       hasta que compre de nuevo.
 */

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

DECLARE @Email NVARCHAR(320) = N'tu@email.com';           -- <-- cambiar
DECLARE @CatalogItemId UNIQUEIDENTIFIER = NULL;             -- NULL = todos los ítems con acceso definitivo
DECLARE @PrepSlug NVARCHAR(160) = NULL;                     -- ej. N'mi-simulacro-abc12345'
DECLARE @DeletePurchases BIT = 1;                            -- 1 = borrar compras prep_access relacionadas
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
   AND @PrepSlug IS NOT NULL
   AND LTRIM(RTRIM(@PrepSlug)) <> N''
BEGIN
    SELECT TOP (1) @CatalogItemId = i.CatalogItemId
    FROM catalog.PrepCatalogItems i
    WHERE i.IsDeleted = 0
      AND i.Slug = LOWER(LTRIM(RTRIM(@PrepSlug)))
    ORDER BY i.CreatedAt DESC;
END;

IF @PrepSlug IS NOT NULL
   AND LTRIM(RTRIM(@PrepSlug)) <> N''
   AND @CatalogItemId IS NULL
BEGIN
    RAISERROR(N'Ítem Prep+ no encontrado con slug: %s', 16, 1, @PrepSlug);
    RETURN;
END;

IF OBJECT_ID('tempdb..#LifetimeAccess') IS NOT NULL
    DROP TABLE #LifetimeAccess;

CREATE TABLE #LifetimeAccess (
    QuizAccessId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    QuizId UNIQUEIDENTIFIER NOT NULL,
    PrepCatalogItemId UNIQUEIDENTIFIER NULL,
    GrantedByPurchaseId UNIQUEIDENTIFIER NULL,
    ItemTitle NVARCHAR(300) NULL,
    ItemSlug NVARCHAR(160) NULL
);

INSERT INTO #LifetimeAccess (
    QuizAccessId,
    QuizId,
    PrepCatalogItemId,
    GrantedByPurchaseId,
    ItemTitle,
    ItemSlug)
SELECT
    qa.QuizAccessId,
    qa.QuizId,
    qa.PrepCatalogItemId,
    qa.GrantedByPurchaseId,
    COALESCE(i.TitleOverride, q.Title),
    i.Slug
FROM sharing.QuizAccesses qa
INNER JOIN quiz.Quizzes q ON q.QuizId = qa.QuizId
LEFT JOIN catalog.PrepCatalogItems i ON i.CatalogItemId = qa.PrepCatalogItemId
WHERE qa.UserId = @UserId
  AND qa.AccessType = N'purchase'
  AND qa.IsLifetimeAccess = 1
  AND qa.ClassId IS NULL
  AND qa.AssignmentId IS NULL
  AND (@CatalogItemId IS NULL OR qa.PrepCatalogItemId = @CatalogItemId);

IF NOT EXISTS (SELECT 1 FROM #LifetimeAccess)
BEGIN
    PRINT N'No hay acceso definitivo Prep+ para este usuario';
    IF @CatalogItemId IS NOT NULL
        PRINT N'(filtro CatalogItemId: ' + CONVERT(NVARCHAR(36), @CatalogItemId) + N')';
    RETURN;
END;

IF OBJECT_ID('tempdb..#PurchaseIds') IS NOT NULL
    DROP TABLE #PurchaseIds;

CREATE TABLE #PurchaseIds (
    PurchaseId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY
);

INSERT INTO #PurchaseIds (PurchaseId)
SELECT DISTINCT la.GrantedByPurchaseId
FROM #LifetimeAccess la
WHERE la.GrantedByPurchaseId IS NOT NULL;

/* Compras prep_access del usuario cuyo ProductCode apunta a ofertas lifetime de esos ítems */
INSERT INTO #PurchaseIds (PurchaseId)
SELECT DISTINCT p.PurchaseId
FROM billing.Purchases p
INNER JOIN catalog.PrepAccessOffers o
    ON o.IsLifetimeAccess = 1
   AND o.IsActive = 1
   AND p.ProductCode = LOWER(REPLACE(CONVERT(NVARCHAR(36), o.CatalogItemId), N'-', N''))
                      + N'|' + LOWER(REPLACE(CONVERT(NVARCHAR(36), o.OfferId), N'-', N''))
INNER JOIN #LifetimeAccess la ON la.PrepCatalogItemId = o.CatalogItemId
WHERE p.UserId = @UserId
  AND p.ProductType = N'prep_access'
  AND p.PurchaseId NOT IN (SELECT PurchaseId FROM #PurchaseIds);

PRINT N'--- RemoveUserPrepPlusLifetimeAccess ---';
PRINT N'Usuario: ' + @Email + N' (' + CONVERT(NVARCHAR(36), @UserId) + N')';
IF @CatalogItemId IS NOT NULL
    PRINT N'Filtro CatalogItemId: ' + CONVERT(NVARCHAR(36), @CatalogItemId);
ELSE
    PRINT N'Ámbito: todos los accesos definitivos Prep+ del usuario';
PRINT N'DeletePurchases: ' + CASE WHEN @DeletePurchases = 1 THEN N'SÍ' ELSE N'NO' END;
PRINT N'DryRun: ' + CASE WHEN @DryRun = 1 THEN N'SÍ (solo vista previa)' ELSE N'NO (ejecutando)' END;
PRINT N'';

SELECT
    la.QuizAccessId,
    la.PrepCatalogItemId,
    la.QuizId,
    la.ItemTitle,
    la.ItemSlug,
    la.GrantedByPurchaseId
FROM #LifetimeAccess la
ORDER BY la.ItemTitle;

SELECT N'QuizAccesses (lifetime)' AS [Acción], COUNT(*) AS [Filas]
FROM #LifetimeAccess;

IF @DeletePurchases = 1
BEGIN
    SELECT N'Purchases (prep_access)' AS [Acción], COUNT(*) AS [Filas]
    FROM #PurchaseIds;
END;

IF @DryRun = 1
BEGIN
    PRINT N'';
    PRINT N'Sin cambios (DryRun=1). Para aplicar: SET @DryRun = 0';
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    DELETE qa
    FROM sharing.QuizAccesses qa
    INNER JOIN #LifetimeAccess la ON la.QuizAccessId = qa.QuizAccessId;

    IF @DeletePurchases = 1
    BEGIN
        DELETE p
        FROM billing.Purchases p
        INNER JOIN #PurchaseIds pid ON pid.PurchaseId = p.PurchaseId
        WHERE p.UserId = @UserId
          AND p.ProductType = N'prep_access';
    END;

    COMMIT TRANSACTION;

    PRINT N'';
    PRINT N'Acceso definitivo Prep+ eliminado correctamente.';
    IF @DeletePurchases = 0
        PRINT N'Nota: las compras prep_access siguen en billing.Purchases; el usuario podría no poder recomprar acceso definitivo hasta limpiarlas.';
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
