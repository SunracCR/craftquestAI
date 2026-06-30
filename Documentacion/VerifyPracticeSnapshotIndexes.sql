-- Verifica índices de snapshots de práctica y lecturas de quiz usados al iniciar sesiones.
-- Ejecutar en producción; si algún índice falta, aplicar el CREATE correspondiente.

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes i
    INNER JOIN sys.tables t ON i.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'practice'
        AND t.name = 'PracticeQuestionSnapshots'
        AND i.name = 'IX_PracticeQuestionSnapshots_SessionOrder')
BEGIN
    PRINT 'FALTA: IX_PracticeQuestionSnapshots_SessionOrder';
    CREATE INDEX IX_PracticeQuestionSnapshots_SessionOrder
        ON practice.PracticeQuestionSnapshots(PracticeSessionId, DisplayOrder);
END
ELSE
BEGIN
    PRINT 'OK: IX_PracticeQuestionSnapshots_SessionOrder';
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes i
    INNER JOIN sys.tables t ON i.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'practice'
        AND t.name = 'PracticeAnswerOptionSnapshots'
        AND i.name = 'IX_PracticeAnswerOptionSnapshots_QuestionOrder')
BEGIN
    PRINT 'FALTA: IX_PracticeAnswerOptionSnapshots_QuestionOrder';
    CREATE INDEX IX_PracticeAnswerOptionSnapshots_QuestionOrder
        ON practice.PracticeAnswerOptionSnapshots(PracticeQuestionSnapshotId, DisplayOrder);
END
ELSE
BEGIN
    PRINT 'OK: IX_PracticeAnswerOptionSnapshots_QuestionOrder';
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes i
    INNER JOIN sys.tables t ON i.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'quiz'
        AND t.name = 'QuestionAnswerOptions'
        AND i.name = 'IX_QuestionAnswerOptions_Question')
BEGIN
    PRINT 'FALTA: IX_QuestionAnswerOptions_Question';
    CREATE INDEX IX_QuestionAnswerOptions_Question
        ON quiz.QuestionAnswerOptions(QuestionId, DefaultSortOrder)
        WHERE IsActive = 1;
END
ELSE
BEGIN
    PRINT 'OK: IX_QuestionAnswerOptions_Question';
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes i
    INNER JOIN sys.tables t ON i.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'quiz'
        AND t.name = 'Questions'
        AND i.name = 'IX_Questions_Quiz')
BEGIN
    PRINT 'FALTA: IX_Questions_Quiz';
    CREATE INDEX IX_Questions_Quiz
        ON quiz.Questions(QuizId, SortOrder)
        WHERE DeletedAt IS NULL;
END
ELSE
BEGIN
    PRINT 'OK: IX_Questions_Quiz';
END
GO
