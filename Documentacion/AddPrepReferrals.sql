/* Prep+ sharing: slugs, referral codes, conversions, purchase attribution.
   Ejecutar una vez en Azure SQL. Idempotente. */

SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('catalog.PrepCatalogItems', 'Slug') IS NULL
BEGIN
    ALTER TABLE catalog.PrepCatalogItems ADD Slug NVARCHAR(160) NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_PrepCatalogItems_Slug' AND object_id = OBJECT_ID(N'catalog.PrepCatalogItems'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_PrepCatalogItems_Slug ON catalog.PrepCatalogItems (Slug) WHERE Slug IS NOT NULL;
END
GO

UPDATE i SET Slug = LEFT(LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(NULLIF(LTRIM(RTRIM(i.TitleOverride)), N''), q.Title), N' ', N'-'), N'á', N'a'), N'é', N'e'), N'í', N'i'), N'ó', N'o'), N'ú', N'u'), N'ñ', N'n'), N'ü', N'u'), N'Á', N'a'), N'É', N'e'), N'Í', N'i'), N'Ó', N'o'), N'Ú', N'u'), N'Ñ', N'n')), 120) + N'-' + LEFT(REPLACE(CAST(i.CatalogItemId AS NVARCHAR(36)), N'-', N''), 8)
FROM catalog.PrepCatalogItems i INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId WHERE i.Slug IS NULL;
GO

IF OBJECT_ID(N'catalog.PrepReferralCodes', N'U') IS NULL
BEGIN
    CREATE TABLE catalog.PrepReferralCodes (
        ReferralCodeId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_PrepReferralCodes PRIMARY KEY,
        Code NVARCHAR(20) NOT NULL,
        CatalogItemId UNIQUEIDENTIFIER NOT NULL,
        ReferrerUserId UNIQUEIDENTIFIER NOT NULL,
        CreatedAt DATETIME2 NOT NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_PrepReferralCodes_IsActive DEFAULT (1),
        CONSTRAINT FK_PrepReferralCodes_CatalogItem FOREIGN KEY (CatalogItemId) REFERENCES catalog.PrepCatalogItems (CatalogItemId),
        CONSTRAINT FK_PrepReferralCodes_ReferrerUser FOREIGN KEY (ReferrerUserId) REFERENCES core.Users (UserId)
    );
    CREATE UNIQUE NONCLUSTERED INDEX UX_PrepReferralCodes_Code ON catalog.PrepReferralCodes (Code);
    CREATE UNIQUE NONCLUSTERED INDEX UX_PrepReferralCodes_Referrer_CatalogItem ON catalog.PrepReferralCodes (ReferrerUserId, CatalogItemId);
END
GO

IF OBJECT_ID(N'catalog.PrepReferralConversions', N'U') IS NULL
BEGIN
    CREATE TABLE catalog.PrepReferralConversions (
        PrepReferralConversionId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_PrepReferralConversions PRIMARY KEY,
        ReferralCodeId UNIQUEIDENTIFIER NOT NULL,
        ReferrerUserId UNIQUEIDENTIFIER NOT NULL,
        BuyerUserId UNIQUEIDENTIFIER NOT NULL,
        CatalogItemId UNIQUEIDENTIFIER NOT NULL,
        PurchaseId UNIQUEIDENTIFIER NOT NULL,
        RewardDaysGranted INT NOT NULL CONSTRAINT DF_PrepReferralConversions_RewardDays DEFAULT (30),
        CreatedAt DATETIME2 NOT NULL,
        CONSTRAINT FK_PrepReferralConversions_ReferralCode FOREIGN KEY (ReferralCodeId) REFERENCES catalog.PrepReferralCodes (ReferralCodeId),
        CONSTRAINT FK_PrepReferralConversions_ReferrerUser FOREIGN KEY (ReferrerUserId) REFERENCES core.Users (UserId),
        CONSTRAINT FK_PrepReferralConversions_BuyerUser FOREIGN KEY (BuyerUserId) REFERENCES core.Users (UserId),
        CONSTRAINT FK_PrepReferralConversions_CatalogItem FOREIGN KEY (CatalogItemId) REFERENCES catalog.PrepCatalogItems (CatalogItemId),
        CONSTRAINT FK_PrepReferralConversions_Purchase FOREIGN KEY (PurchaseId) REFERENCES billing.Purchases (PurchaseId)
    );
    CREATE UNIQUE NONCLUSTERED INDEX UX_PrepReferralConversions_PurchaseId ON catalog.PrepReferralConversions (PurchaseId);
    CREATE UNIQUE NONCLUSTERED INDEX UX_PrepReferralConversions_Referrer_Buyer_Item ON catalog.PrepReferralConversions (ReferrerUserId, BuyerUserId, CatalogItemId);
END
GO

IF COL_LENGTH('billing.Purchases', 'PrepReferralCodeId') IS NULL
BEGIN
    ALTER TABLE billing.Purchases ADD PrepReferralCodeId UNIQUEIDENTIFIER NULL;
    ALTER TABLE billing.Purchases ADD CONSTRAINT FK_Purchases_PrepReferralCode FOREIGN KEY (PrepReferralCodeId) REFERENCES catalog.PrepReferralCodes (ReferralCodeId);
END
GO
