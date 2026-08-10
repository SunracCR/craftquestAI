/* Prep+ lifetime (permanent) quiz access. */

IF COL_LENGTH('catalog.PrepAccessOffers', 'IsLifetimeAccess') IS NULL
BEGIN
    ALTER TABLE catalog.PrepAccessOffers
        ADD IsLifetimeAccess BIT NOT NULL
            CONSTRAINT DF_PrepAccessOffers_IsLifetimeAccess DEFAULT (0);
END
GO

IF COL_LENGTH('sharing.QuizAccesses', 'IsLifetimeAccess') IS NULL
BEGIN
    ALTER TABLE sharing.QuizAccesses
        ADD IsLifetimeAccess BIT NOT NULL
            CONSTRAINT DF_QuizAccesses_IsLifetimeAccess DEFAULT (0);
END
GO

/* Legacy schema only allowed timed durations (30/60/90/183). Lifetime uses DurationDays = 0. */
IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = 'CK_PrepAccessOffers_Duration'
      AND parent_object_id = OBJECT_ID('catalog.PrepAccessOffers'))
BEGIN
    ALTER TABLE catalog.PrepAccessOffers DROP CONSTRAINT CK_PrepAccessOffers_Duration;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = 'CK_PrepAccessOffers_Duration'
      AND parent_object_id = OBJECT_ID('catalog.PrepAccessOffers'))
BEGIN
    ALTER TABLE catalog.PrepAccessOffers
        ADD CONSTRAINT CK_PrepAccessOffers_Duration CHECK (
            (IsLifetimeAccess = 1 AND DurationDays = 0)
            OR (IsLifetimeAccess = 0 AND DurationDays IN (30, 60, 90, 183)));
END
GO

IF EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'UQ_PrepAccessOffers_ItemDuration'
      AND parent_object_id = OBJECT_ID('catalog.PrepAccessOffers'))
BEGIN
    ALTER TABLE catalog.PrepAccessOffers DROP CONSTRAINT UQ_PrepAccessOffers_ItemDuration;
END
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'UX_PrepAccessOffers_CatalogItemId_DurationDays'
      AND object_id = OBJECT_ID('catalog.PrepAccessOffers'))
BEGIN
    DROP INDEX UX_PrepAccessOffers_CatalogItemId_DurationDays ON catalog.PrepAccessOffers;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'UX_PrepAccessOffers_CatalogItem_TimedDuration'
      AND object_id = OBJECT_ID('catalog.PrepAccessOffers'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_PrepAccessOffers_CatalogItem_TimedDuration
        ON catalog.PrepAccessOffers (CatalogItemId, DurationDays)
        WHERE IsLifetimeAccess = 0;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'UX_PrepAccessOffers_CatalogItem_Lifetime'
      AND object_id = OBJECT_ID('catalog.PrepAccessOffers'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_PrepAccessOffers_CatalogItem_Lifetime
        ON catalog.PrepAccessOffers (CatalogItemId)
        WHERE IsLifetimeAccess = 1;
END
GO
