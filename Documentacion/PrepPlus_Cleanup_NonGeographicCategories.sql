/*
  CraftQuest — Prep+: eliminar TODAS las categorías que NO sean geographic.

  Afecta CategoryType = 'thematic' (p. ej. raíz Internacional y sus hijas)
  y cualquier otra fila con tipo distinto de geographic.

  Orden: accesos Prep → ítems de catálogo → subcategorías (hojas) → raíces.

  IMPORTANTE:
  - Revisa el PASO 1 antes de confirmar el borrado.
  - Los quizzes en quiz.Quizzes NO se borran; solo el listado Prep+.
  - Para deshacer necesitas backup o re-ejecutar PrepPlus_Seed_Categories.sql (parcial).

  Ejecutar en la base de datos de CraftQuest (SSMS / Azure Data Studio).
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

/* ========== PASO 1: Vista previa (solo lectura) ========== */
PRINT N'--- Categorías que se eliminarán (no geographic) ---';

SELECT
    c.CategoryId,
    c.ParentCategoryId,
    c.CategoryType,
    c.Slug,
    c.Name,
    c.IsActive,
    (SELECT COUNT(*)
     FROM catalog.PrepCategories ch
     WHERE ch.ParentCategoryId = c.CategoryId) AS Hijos,
    (SELECT COUNT(*)
     FROM catalog.PrepCatalogItems i
     WHERE i.CategoryId = c.CategoryId AND i.IsDeleted = 0) AS ItemsActivos
FROM catalog.PrepCategories c
WHERE c.CategoryType <> N'geographic'
ORDER BY c.ParentCategoryId, c.SortOrder, c.Name;

PRINT N'--- Ítems Prep+ en esas categorías ---';

SELECT
    i.CatalogItemId,
    i.CategoryId,
    c.Slug AS CategorySlug,
    c.Name AS CategoryName,
    i.IsPublished,
    i.IsDeleted,
    q.Title AS QuizTitle
FROM catalog.PrepCatalogItems i
INNER JOIN catalog.PrepCategories c ON c.CategoryId = i.CategoryId
INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId
WHERE c.CategoryType <> N'geographic'
ORDER BY c.Name, i.CreatedAt;

PRINT N'--- Resumen ---';

SELECT
    (SELECT COUNT(*) FROM catalog.PrepCategories WHERE CategoryType <> N'geographic') AS CategoriasABorrar,
    (SELECT COUNT(*)
     FROM catalog.PrepCatalogItems i
     INNER JOIN catalog.PrepCategories c ON c.CategoryId = i.CategoryId
     WHERE c.CategoryType <> N'geographic') AS ItemsCatalogoABorrar,
    (SELECT COUNT(*)
     FROM catalog.PrepCategories WHERE CategoryType = N'geographic') AS CategoriasGeographicQueQuedan;

GO

/* ========== PASO 2: Borrado (descomenta tras revisar el PASO 1) ========== */
/*
BEGIN TRANSACTION;

-- 2a) Desvincular accesos que apunten a ítems Prep+ en categorías no geographic
IF COL_LENGTH('sharing.QuizAccesses', 'PrepCatalogItemId') IS NOT NULL
BEGIN
    UPDATE qa
    SET qa.PrepCatalogItemId = NULL
    FROM sharing.QuizAccesses qa
    INNER JOIN catalog.PrepCatalogItems i ON i.CatalogItemId = qa.PrepCatalogItemId
    INNER JOIN catalog.PrepCategories c ON c.CategoryId = i.CategoryId
    WHERE c.CategoryType <> N'geographic';
END

-- 2b) Ítems de catálogo (ofertas y muestras se eliminan por ON DELETE CASCADE)
DELETE i
FROM catalog.PrepCatalogItems i
INNER JOIN catalog.PrepCategories c ON c.CategoryId = i.CategoryId
WHERE c.CategoryType <> N'geographic';

-- 2c) Categorías: repetir hasta vaciar (hojas primero por FK_PrepCategories_Parent)
DECLARE @Filas INT = 1;

WHILE @Filas > 0
BEGIN
    DELETE FROM catalog.PrepCategories
    WHERE CategoryType <> N'geographic'
      AND NOT EXISTS (
          SELECT 1
          FROM catalog.PrepCategories hijo
          WHERE hijo.ParentCategoryId = catalog.PrepCategories.CategoryId
      );

    SET @Filas = @@ROWCOUNT;
END

-- 2d) Comprobación final
IF EXISTS (SELECT 1 FROM catalog.PrepCategories WHERE CategoryType <> N'geographic')
BEGIN
    ROLLBACK TRANSACTION;
    RAISERROR(N'Quedan categorías no geographic. Revisa hijos huérfanos o tipos inconsistentes.', 16, 1);
    RETURN;
END

PRINT N'Borrado completado. Categorías geographic restantes:';
SELECT CategoryId, ParentCategoryId, Slug, Name, CategoryType
FROM catalog.PrepCategories
ORDER BY ParentCategoryId, SortOrder;

-- COMMIT TRANSACTION;
-- ROLLBACK TRANSACTION;  -- usa esto en lugar de COMMIT si fue una prueba
*/
