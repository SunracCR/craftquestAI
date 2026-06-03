-- Justificaciones: columnas de fuente y snapshot en práctica.
-- Ejecutar en la base CraftQuest existente (idempotente).

IF COL_LENGTH('quiz.QuestionJustificationSources', 'SourcePageNumber') IS NULL
BEGIN
    ALTER TABLE quiz.QuestionJustificationSources
        ADD SourcePageNumber INT NULL;
END
GO

IF COL_LENGTH('quiz.QuestionJustificationSources', 'StudyMaterialId') IS NULL
BEGIN
    ALTER TABLE quiz.QuestionJustificationSources
        ADD StudyMaterialId UNIQUEIDENTIFIER NULL;
END
GO

IF COL_LENGTH('practice.PracticeQuestionSnapshots', 'JustificationTextSnapshot') IS NULL
BEGIN
    ALTER TABLE practice.PracticeQuestionSnapshots
        ADD JustificationTextSnapshot NVARCHAR(MAX) NULL;
END
GO

IF COL_LENGTH('practice.PracticeQuestionSnapshots', 'JustificationSourcesSnapshot') IS NULL
BEGIN
    ALTER TABLE practice.PracticeQuestionSnapshots
        ADD JustificationSourcesSnapshot NVARCHAR(MAX) NULL;
END
GO
