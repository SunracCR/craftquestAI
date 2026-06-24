/* Carpetas jerárquicas para organizar cuestionarios del profesor.
   Ejecutar una vez en Azure SQL. Idempotente.
   No usar dotnet ef migrations: CraftQuest aplica cambios de esquema con scripts SQL. */

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('quiz.QuizFolders', 'U') IS NULL
BEGIN
    CREATE TABLE quiz.QuizFolders (
        QuizFolderId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_QuizFolders PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
        OwnerUserId UNIQUEIDENTIFIER NOT NULL,
        Name NVARCHAR(160) NOT NULL,
        ParentFolderId UNIQUEIDENTIFIER NULL,
        Depth INT NOT NULL CONSTRAINT DF_QuizFolders_Depth DEFAULT(0),
        SortOrder INT NOT NULL CONSTRAINT DF_QuizFolders_SortOrder DEFAULT(0),
        CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_QuizFolders_CreatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2(7) NULL,
        DeletedAt DATETIME2(7) NULL,
        CONSTRAINT FK_QuizFolders_Users FOREIGN KEY (OwnerUserId) REFERENCES core.Users(UserId),
        CONSTRAINT FK_QuizFolders_Parent FOREIGN KEY (ParentFolderId) REFERENCES quiz.QuizFolders(QuizFolderId),
        CONSTRAINT CK_QuizFolders_Depth CHECK (Depth >= 0 AND Depth <= 2)
    );
END
GO

IF COL_LENGTH('quiz.Quizzes', 'FolderId') IS NULL
BEGIN
    ALTER TABLE quiz.Quizzes ADD FolderId UNIQUEIDENTIFIER NULL;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_Quizzes_QuizFolders'
      AND parent_object_id = OBJECT_ID(N'quiz.Quizzes'))
BEGIN
    ALTER TABLE quiz.Quizzes
        ADD CONSTRAINT FK_Quizzes_QuizFolders
        FOREIGN KEY (FolderId) REFERENCES quiz.QuizFolders(QuizFolderId)
        ON DELETE SET NULL;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_QuizFolders_Owner'
      AND object_id = OBJECT_ID(N'quiz.QuizFolders'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_QuizFolders_Owner
        ON quiz.QuizFolders (OwnerUserId, ParentFolderId, SortOrder)
        WHERE DeletedAt IS NULL;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_Quizzes_Folder'
      AND object_id = OBJECT_ID(N'quiz.Quizzes'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Quizzes_Folder
        ON quiz.Quizzes (FolderId)
        WHERE DeletedAt IS NULL;
END
GO
