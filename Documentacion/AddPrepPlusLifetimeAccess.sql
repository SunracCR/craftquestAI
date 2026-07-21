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

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'UX_PrepAccessOffers_CatalogItemId_DurationDays'
      AND object_id = OBJECT_ID('catalog.PrepAccessOffers'))
BEGIN
    DROP INDEX UX_PrepAccessOffers_CatalogItemId_DurationDays ON catalog.PrepAccessOffers;
END
GO

CREATE UNIQUE NONCLUSTERED INDEX UX_PrepAccessOffers_CatalogItem_TimedDuration
    ON catalog.PrepAccessOffers (CatalogItemId, DurationDays)
    WHERE IsLifetimeAccess = 0;
GO

CREATE UNIQUE NONCLUSTERED INDEX UX_PrepAccessOffers_CatalogItem_Lifetime
    ON catalog.PrepAccessOffers (CatalogItemId)
    WHERE IsLifetimeAccess = 1;
GO
