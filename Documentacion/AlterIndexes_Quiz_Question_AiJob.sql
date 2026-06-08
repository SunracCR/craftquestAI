/* Índices alineados con EF (QuizConfiguration, QuestionConfiguration, AiJobConfiguration).
   Ejecutar una vez en Azure SQL. Idempotente.
   No usar dotnet ef migrations: CraftQuest aplica cambios de esquema con scripts SQL. */

SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_Quizzes_CreatedByUser_CreatedAt'
      AND object_id = OBJECT_ID(N'quiz.Quizzes'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Quizzes_CreatedByUser_CreatedAt
        ON quiz.Quizzes (CreatedByUserId, CreatedAt DESC)
        WHERE DeletedAt IS NULL;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_Questions_Quiz'
      AND object_id = OBJECT_ID(N'quiz.Questions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Questions_Quiz
        ON quiz.Questions (QuizId, SortOrder)
        WHERE DeletedAt IS NULL;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_AiJobs_PendingImportByQuiz'
      AND object_id = OBJECT_ID(N'ai.AiJobs'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_AiJobs_PendingImportByQuiz
        ON ai.AiJobs (RequestedByUserId, JobType, Status, TargetQuizId)
        INCLUDE (CompletedAt, QuestionImportBatchId)
        WHERE TargetQuizId IS NOT NULL;
END
GO
