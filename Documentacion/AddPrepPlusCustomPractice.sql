/* Prep+ custom practice: sections/topics taxonomy and catalog flag. */

IF COL_LENGTH('catalog.PrepCatalogItems', 'SupportsCustomPractice') IS NULL
BEGIN
    ALTER TABLE catalog.PrepCatalogItems
        ADD SupportsCustomPractice BIT NOT NULL
            CONSTRAINT DF_PrepCatalogItems_SupportsCustomPractice DEFAULT (0);
END
GO

IF OBJECT_ID('quiz.QuizTopics', 'U') IS NULL
BEGIN
    CREATE TABLE quiz.QuizTopics (
        QuizTopicId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_QuizTopics PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
        QuizId UNIQUEIDENTIFIER NOT NULL,
        QuizSectionId UNIQUEIDENTIFIER NOT NULL,
        Name NVARCHAR(160) NOT NULL,
        SortOrder INT NOT NULL CONSTRAINT DF_QuizTopics_SortOrder DEFAULT (0),
        CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_QuizTopics_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_QuizTopics_Quizzes FOREIGN KEY (QuizId) REFERENCES quiz.Quizzes(QuizId),
        CONSTRAINT FK_QuizTopics_QuizSections FOREIGN KEY (QuizSectionId) REFERENCES quiz.QuizSections(QuizSectionId),
        CONSTRAINT UQ_QuizTopics_SectionName UNIQUE (QuizSectionId, Name)
    );
END
GO

IF COL_LENGTH('quiz.Questions', 'QuizTopicId') IS NULL
BEGIN
    ALTER TABLE quiz.Questions
        ADD QuizTopicId UNIQUEIDENTIFIER NULL;

    ALTER TABLE quiz.Questions
        ADD CONSTRAINT FK_Questions_QuizTopics
            FOREIGN KEY (QuizTopicId) REFERENCES quiz.QuizTopics(QuizTopicId);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Questions_QuizSectionId'
      AND object_id = OBJECT_ID('quiz.Questions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Questions_QuizSectionId
        ON quiz.Questions (QuizSectionId)
        WHERE QuizSectionId IS NOT NULL AND DeletedAt IS NULL;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Questions_QuizTopicId'
      AND object_id = OBJECT_ID('quiz.Questions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Questions_QuizTopicId
        ON quiz.Questions (QuizTopicId)
        WHERE QuizTopicId IS NOT NULL AND DeletedAt IS NULL;
END
GO
