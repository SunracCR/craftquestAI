/* Study materials AI generation — extends content.StudyMaterials + new tables */

IF COL_LENGTH('content.StudyMaterials', 'Title') IS NULL
    ALTER TABLE content.StudyMaterials ADD Title NVARCHAR(260) NULL;
GO

IF COL_LENGTH('content.StudyMaterials', 'OriginalFileName') IS NULL
    ALTER TABLE content.StudyMaterials ADD OriginalFileName NVARCHAR(260) NULL;
GO

IF COL_LENGTH('content.StudyMaterials', 'FileSizeBytes') IS NULL
    ALTER TABLE content.StudyMaterials ADD FileSizeBytes BIGINT NULL;
GO

IF COL_LENGTH('content.StudyMaterials', 'PageCount') IS NULL
    ALTER TABLE content.StudyMaterials ADD PageCount INT NULL;
GO

IF COL_LENGTH('content.StudyMaterials', 'WordCount') IS NULL
    ALTER TABLE content.StudyMaterials ADD WordCount INT NULL;
GO

IF COL_LENGTH('content.StudyMaterials', 'LanguageCode') IS NULL
    ALTER TABLE content.StudyMaterials ADD LanguageCode NVARCHAR(10) NULL;
GO

IF COL_LENGTH('content.StudyMaterials', 'ErrorMessage') IS NULL
    ALTER TABLE content.StudyMaterials ADD ErrorMessage NVARCHAR(2000) NULL;
GO

IF COL_LENGTH('content.StudyMaterials', 'NeedsOcr') IS NULL
    ALTER TABLE content.StudyMaterials ADD NeedsOcr BIT NOT NULL CONSTRAINT DF_StudyMaterials_NeedsOcr DEFAULT(0);
GO

IF COL_LENGTH('content.StudyMaterials', 'RetentionExpiresAt') IS NULL
    ALTER TABLE content.StudyMaterials ADD RetentionExpiresAt DATETIME2(7) NULL;
GO

IF COL_LENGTH('content.StudyMaterials', 'IsPinned') IS NULL
    ALTER TABLE content.StudyMaterials ADD IsPinned BIT NOT NULL CONSTRAINT DF_StudyMaterials_IsPinned DEFAULT(0);
GO

IF COL_LENGTH('content.StudyMaterials', 'SelectionPageFrom') IS NULL
    ALTER TABLE content.StudyMaterials ADD SelectionPageFrom INT NULL;
GO

IF COL_LENGTH('content.StudyMaterials', 'SelectionPageTo') IS NULL
    ALTER TABLE content.StudyMaterials ADD SelectionPageTo INT NULL;
GO

IF COL_LENGTH('content.StudyMaterials', 'SelectionTopic') IS NULL
    ALTER TABLE content.StudyMaterials ADD SelectionTopic NVARCHAR(500) NULL;
GO

IF COL_LENGTH('content.StudyMaterials', 'BlobPath') IS NULL
    ALTER TABLE content.StudyMaterials ADD BlobPath NVARCHAR(1000) NULL;
GO

IF OBJECT_ID('content.StudyMaterialPages', 'U') IS NULL
CREATE TABLE content.StudyMaterialPages (
    StudyMaterialPageId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_StudyMaterialPages PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    StudyMaterialId UNIQUEIDENTIFIER NOT NULL,
    PageNumber INT NOT NULL,
    ExtractedText NVARCHAR(MAX) NULL,
    WordCount INT NOT NULL CONSTRAINT DF_StudyMaterialPages_WordCount DEFAULT(0),
    HasEmbeddedImages BIT NOT NULL CONSTRAINT DF_StudyMaterialPages_HasImages DEFAULT(0),
    ExtractionQuality NVARCHAR(20) NOT NULL CONSTRAINT DF_StudyMaterialPages_Quality DEFAULT('good'),
    CONSTRAINT FK_StudyMaterialPages_Materials FOREIGN KEY (StudyMaterialId) REFERENCES content.StudyMaterials(StudyMaterialId) ON DELETE CASCADE,
    CONSTRAINT UQ_StudyMaterialPages_Page UNIQUE (StudyMaterialId, PageNumber),
    CONSTRAINT CK_StudyMaterialPages_Quality CHECK (ExtractionQuality IN ('good','low','empty'))
);
GO

IF OBJECT_ID('content.StudyMaterialSections', 'U') IS NULL
CREATE TABLE content.StudyMaterialSections (
    StudyMaterialSectionId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_StudyMaterialSections PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    StudyMaterialId UNIQUEIDENTIFIER NOT NULL,
    Title NVARCHAR(300) NOT NULL,
    PageFrom INT NOT NULL,
    PageTo INT NOT NULL,
    SortOrder INT NOT NULL CONSTRAINT DF_StudyMaterialSections_SortOrder DEFAULT(0),
    CONSTRAINT FK_StudyMaterialSections_Materials FOREIGN KEY (StudyMaterialId) REFERENCES content.StudyMaterials(StudyMaterialId) ON DELETE CASCADE
);
GO

IF COL_LENGTH('content.StudyMaterials', 'EditedExtractedText') IS NULL
    ALTER TABLE content.StudyMaterials ADD EditedExtractedText NVARCHAR(MAX) NULL;
GO

IF COL_LENGTH('content.StudyMaterialPages', 'ImageBlobPath') IS NULL
    ALTER TABLE content.StudyMaterialPages ADD ImageBlobPath NVARCHAR(1000) NULL;
GO

IF COL_LENGTH('ai.AiJobs', 'InputJson') IS NULL
    ALTER TABLE ai.AiJobs ADD InputJson NVARCHAR(MAX) NULL;
GO

IF COL_LENGTH('ai.AiJobs', 'QuestionImportBatchId') IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AiJobs_PendingGenerate' AND object_id = OBJECT_ID('ai.AiJobs'))
    CREATE INDEX IX_AiJobs_PendingGenerate ON ai.AiJobs (Status, JobType) WHERE Status IN ('pending','processing');
GO
