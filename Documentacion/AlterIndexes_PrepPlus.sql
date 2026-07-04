/* Índices alineados con EF (PrepCatalogItemConfiguration, QuizAccessConfiguration).
   Ejecutar una vez en Azure SQL. Idempotente.
   No usar dotnet ef migrations: CraftQuest aplica cambios de esquema con scripts SQL. */

SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_PrepCatalogItems_CategoryId_IsPublished_IsDeleted'
      AND object_id = OBJECT_ID(N'catalog.PrepCatalogItems'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_PrepCatalogItems_CategoryId_IsPublished_IsDeleted
        ON catalog.PrepCatalogItems (CategoryId, IsPublished, IsDeleted);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_QuizAccesses_UserId_AccessType_PrepCatalogItemId'
      AND object_id = OBJECT_ID(N'sharing.QuizAccesses'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_QuizAccesses_UserId_AccessType_PrepCatalogItemId
        ON sharing.QuizAccesses (UserId, AccessType, PrepCatalogItemId);
END
GO
