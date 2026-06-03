/* Preparación+ — Esquema F1 (catálogo admin + extensiones de acceso)
   Ejecutar contra la base CraftQuest existente. */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'catalog')
    EXEC('CREATE SCHEMA catalog');
GO

/* --- QuizAccess: acceso temporal por compra --- */
IF COL_LENGTH('sharing.QuizAccesses', 'ExpiresAt') IS NULL
    ALTER TABLE sharing.QuizAccesses ADD ExpiresAt DATETIME2(7) NULL;
GO

IF COL_LENGTH('sharing.QuizAccesses', 'GrantedByPurchaseId') IS NULL
    ALTER TABLE sharing.QuizAccesses ADD GrantedByPurchaseId UNIQUEIDENTIFIER NULL;
GO

IF COL_LENGTH('sharing.QuizAccesses', 'PrepCatalogItemId') IS NULL
    ALTER TABLE sharing.QuizAccesses ADD PrepCatalogItemId UNIQUEIDENTIFIER NULL;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = N'FK_QuizAccesses_Purchases'
      AND parent_object_id = OBJECT_ID(N'sharing.QuizAccesses'))
   AND COL_LENGTH('sharing.QuizAccesses', 'GrantedByPurchaseId') IS NOT NULL
BEGIN
    ALTER TABLE sharing.QuizAccesses
        ADD CONSTRAINT FK_QuizAccesses_Purchases
        FOREIGN KEY (GrantedByPurchaseId) REFERENCES billing.Purchases(PurchaseId);
END
GO

/* ProductType prep_access (ampliar CHECK existente) */
IF EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'billing.Purchases')
      AND name = N'CK_Purchases_ProductType')
BEGIN
    ALTER TABLE billing.Purchases DROP CONSTRAINT CK_Purchases_ProductType;
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'billing.Purchases')
      AND name = N'CK_Purchases_ProductType')
BEGIN
    ALTER TABLE billing.Purchases
        ADD CONSTRAINT CK_Purchases_ProductType CHECK (
            ProductType IN (
                'subscription','ai_credits','share_codes','curated_package',
                'teacher_seats','prep_access'));
END
GO

/* --- Categorías --- */
IF OBJECT_ID('catalog.PrepCategories', 'U') IS NULL
CREATE TABLE catalog.PrepCategories (
    CategoryId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_PrepCategories PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    ParentCategoryId UNIQUEIDENTIFIER NULL,
    CategoryType NVARCHAR(20) NOT NULL,
    Slug NVARCHAR(80) NOT NULL,
    Name NVARCHAR(120) NOT NULL,
    Description NVARCHAR(500) NULL,
    CountryCode NVARCHAR(10) NULL,
    IconKey NVARCHAR(60) NULL,
    SortOrder INT NOT NULL CONSTRAINT DF_PrepCategories_SortOrder DEFAULT(0),
    IsActive BIT NOT NULL CONSTRAINT DF_PrepCategories_IsActive DEFAULT(1),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_PrepCategories_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(7) NULL,
    CONSTRAINT FK_PrepCategories_Parent FOREIGN KEY (ParentCategoryId) REFERENCES catalog.PrepCategories(CategoryId),
    CONSTRAINT CK_PrepCategories_Type CHECK (CategoryType IN ('geographic','thematic')),
    CONSTRAINT UQ_PrepCategories_ParentSlug UNIQUE (ParentCategoryId, Slug)
);
GO

/* --- Ítems de catálogo --- */
IF OBJECT_ID('catalog.PrepCatalogItems', 'U') IS NULL
CREATE TABLE catalog.PrepCatalogItems (
    CatalogItemId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_PrepCatalogItems PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    QuizId UNIQUEIDENTIFIER NOT NULL,
    CategoryId UNIQUEIDENTIFIER NOT NULL,
    TitleOverride NVARCHAR(220) NULL,
    Description NVARCHAR(2000) NULL,
    CoverMediaId UNIQUEIDENTIFIER NULL,
    TagsJson NVARCHAR(MAX) NULL,
    InstitutionTag NVARCHAR(120) NULL,
    ListingStartsAt DATETIME2(7) NULL,
    ListingEndsAt DATETIME2(7) NULL,
    IsPublished BIT NOT NULL CONSTRAINT DF_PrepCatalogItems_IsPublished DEFAULT(0),
    PublishedAt DATETIME2(7) NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_PrepCatalogItems_IsDeleted DEFAULT(0),
    CreatedByUserId UNIQUEIDENTIFIER NOT NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_PrepCatalogItems_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(7) NULL,
    CONSTRAINT FK_PrepCatalogItems_Quizzes FOREIGN KEY (QuizId) REFERENCES quiz.Quizzes(QuizId),
    CONSTRAINT FK_PrepCatalogItems_Categories FOREIGN KEY (CategoryId) REFERENCES catalog.PrepCategories(CategoryId),
    CONSTRAINT FK_PrepCatalogItems_Media FOREIGN KEY (CoverMediaId) REFERENCES content.MediaAssets(MediaAssetId),
    CONSTRAINT FK_PrepCatalogItems_Users FOREIGN KEY (CreatedByUserId) REFERENCES core.Users(UserId),
    CONSTRAINT UQ_PrepCatalogItems_Quiz UNIQUE (QuizId)
);
GO

/* --- Ofertas por duración --- */
IF OBJECT_ID('catalog.PrepAccessOffers', 'U') IS NULL
CREATE TABLE catalog.PrepAccessOffers (
    OfferId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_PrepAccessOffers PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    CatalogItemId UNIQUEIDENTIFIER NOT NULL,
    DurationDays INT NOT NULL,
    PriceAmount DECIMAL(12,2) NOT NULL CONSTRAINT DF_PrepAccessOffers_Price DEFAULT(0),
    CurrencyCode NVARCHAR(10) NOT NULL CONSTRAINT DF_PrepAccessOffers_Currency DEFAULT('USD'),
    IsFree BIT NOT NULL CONSTRAINT DF_PrepAccessOffers_IsFree DEFAULT(0),
    StoreProductId NVARCHAR(120) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_PrepAccessOffers_IsActive DEFAULT(1),
    CONSTRAINT FK_PrepAccessOffers_Items FOREIGN KEY (CatalogItemId) REFERENCES catalog.PrepCatalogItems(CatalogItemId) ON DELETE CASCADE,
    CONSTRAINT UQ_PrepAccessOffers_ItemDuration UNIQUE (CatalogItemId, DurationDays),
    CONSTRAINT CK_PrepAccessOffers_Duration CHECK (DurationDays IN (30, 60, 90, 183))
);
GO

/* --- Preguntas de muestra (3) --- */
IF OBJECT_ID('catalog.PrepSampleQuestions', 'U') IS NULL
CREATE TABLE catalog.PrepSampleQuestions (
    CatalogItemId UNIQUEIDENTIFIER NOT NULL,
    QuestionId UNIQUEIDENTIFIER NOT NULL,
    SortOrder INT NOT NULL,
    CONSTRAINT PK_PrepSampleQuestions PRIMARY KEY (CatalogItemId, QuestionId),
    CONSTRAINT FK_PrepSampleQuestions_Items FOREIGN KEY (CatalogItemId) REFERENCES catalog.PrepCatalogItems(CatalogItemId) ON DELETE CASCADE,
    CONSTRAINT FK_PrepSampleQuestions_Questions FOREIGN KEY (QuestionId) REFERENCES quiz.Questions(QuestionId)
);
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = N'FK_QuizAccesses_PrepCatalogItems'
      AND parent_object_id = OBJECT_ID(N'sharing.QuizAccesses'))
   AND COL_LENGTH('sharing.QuizAccesses', 'PrepCatalogItemId') IS NOT NULL
   AND OBJECT_ID(N'catalog.PrepCatalogItems', N'U') IS NOT NULL
BEGIN
    ALTER TABLE sharing.QuizAccesses
        ADD CONSTRAINT FK_QuizAccesses_PrepCatalogItems
        FOREIGN KEY (PrepCatalogItemId) REFERENCES catalog.PrepCatalogItems(CatalogItemId);
END
GO
