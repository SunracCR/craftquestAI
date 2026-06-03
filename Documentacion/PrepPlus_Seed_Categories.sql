/* Semilla opcional — categorías raíz Preparación+ (ejecutar una vez) */

DECLARE @CostaRicaId UNIQUEIDENTIFIER = NEWID();
DECLARE @InternacionalId UNIQUEIDENTIFIER = NEWID();

IF NOT EXISTS (SELECT 1 FROM catalog.PrepCategories WHERE Slug = N'costa-rica' AND ParentCategoryId IS NULL)
BEGIN
    INSERT INTO catalog.PrepCategories (CategoryId, ParentCategoryId, CategoryType, Slug, Name, CountryCode, SortOrder)
    VALUES (@CostaRicaId, NULL, N'geographic', N'costa-rica', N'Costa Rica', N'CR', 10);

    INSERT INTO catalog.PrepCategories (ParentCategoryId, CategoryType, Slug, Name, SortOrder)
    VALUES
        (@CostaRicaId, N'geographic', N'admision', N'Exámenes de admisión', 1),
        (@CostaRicaId, N'geographic', N'estandarizadas', N'Pruebas estandarizadas', 2),
        (@CostaRicaId, N'geographic', N'bachillerato', N'Bachillerato', 3);
END

IF NOT EXISTS (SELECT 1 FROM catalog.PrepCategories WHERE Slug = N'internacional' AND ParentCategoryId IS NULL)
BEGIN
    INSERT INTO catalog.PrepCategories (CategoryId, ParentCategoryId, CategoryType, Slug, Name, SortOrder)
    VALUES (@InternacionalId, NULL, N'thematic', N'internacional', N'Internacional', 20);

    INSERT INTO catalog.PrepCategories (ParentCategoryId, CategoryType, Slug, Name, SortOrder)
    VALUES
        (@InternacionalId, N'thematic', N'amor', N'Amor', 1),
        (@InternacionalId, N'thematic', N'amistad', N'Amistad', 2),
        (@InternacionalId, N'thematic', N'aprendizaje-temprano', N'Aprendizaje temprano', 3),
        (@InternacionalId, N'thematic', N'psicologicos', N'Psicológicos', 4);
END
GO
