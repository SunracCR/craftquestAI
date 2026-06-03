/*
  Limpieza de categorías Prep+ duplicadas (rama completa).
  Ejecutar en CraftQuest después de revisar los resultados del PASO 1.

  Orden: ítems de catálogo → subcategorías (hojas primero) → raíz duplicada.
*/

-- PASO 1: Identificar ramas (ajusta el nombre o slug)
DECLARE @NombreDuplicado NVARCHAR(120) = N'Temas Varios'; -- o el nombre de la raíz duplicada

SELECT
    c.CategoryId,
    c.ParentCategoryId,
    c.Slug,
    c.Name,
    c.IsActive,
    c.CreatedAt,
    (SELECT COUNT(*) FROM catalog.PrepCategories ch
     WHERE ch.ParentCategoryId = c.CategoryId) AS Hijos,
    (SELECT COUNT(*) FROM catalog.PrepCatalogItems i
     WHERE i.CategoryId = c.CategoryId AND i.IsDeleted = 0) AS Items
FROM catalog.PrepCategories c
WHERE c.Name = @NombreDuplicado
   OR c.Slug LIKE N'%temas-varios%'
ORDER BY c.ParentCategoryId, c.CreatedAt;

-- PASO 2: Pegar el CategoryId de la rama DUPLICADA a eliminar (raíz huérfana o copia más reciente)
DECLARE @RamaDuplicada UNIQUEIDENTIFIER = 'PEGAR-GUID-RAIZ-DUPLICADA-AQUI';

-- PASO 3: Borrar en cascada (hijos → padre), solo dentro de esa rama
;WITH Rama AS (
    SELECT CategoryId FROM catalog.PrepCategories WHERE CategoryId = @RamaDuplicada
    UNION ALL
    SELECT c.CategoryId
    FROM catalog.PrepCategories c
    INNER JOIN Rama r ON c.ParentCategoryId = r.CategoryId
)
DELETE FROM catalog.PrepCatalogItems
WHERE CategoryId IN (SELECT CategoryId FROM Rama);

;WITH Rama AS (
    SELECT CategoryId FROM catalog.PrepCategories WHERE CategoryId = @RamaDuplicada
    UNION ALL
    SELECT c.CategoryId
    FROM catalog.PrepCategories c
    INNER JOIN Rama r ON c.ParentCategoryId = r.CategoryId
)
DELETE FROM catalog.PrepCategories
WHERE CategoryId IN (SELECT CategoryId FROM Rama);

-- Alternativa suave (sin DELETE): desactivar toda la rama
/*
;WITH Rama AS (
    SELECT CategoryId FROM catalog.PrepCategories WHERE CategoryId = @RamaDuplicada
    UNION ALL
    SELECT c.CategoryId FROM catalog.PrepCategories c
    INNER JOIN Rama r ON c.ParentCategoryId = r.CategoryId
)
UPDATE catalog.PrepCategories
SET IsActive = 0, UpdatedAt = SYSUTCDATETIME()
WHERE CategoryId IN (SELECT CategoryId FROM Rama);
*/
