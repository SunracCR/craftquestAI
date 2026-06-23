-- Verifica índices de snapshots de práctica usados al reanudar/cargar sesiones.
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
