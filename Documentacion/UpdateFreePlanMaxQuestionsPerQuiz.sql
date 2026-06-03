-- Obsoleto: usar UpdateFreePlanLimits.sql (2 cuestionarios, 50 preguntas).
-- Mantenido por referencia en checklist histórico.
UPDATE billing.Plans
SET
    MaxQuizzes = 2,
    MaxQuestionsPerQuiz = 50
WHERE Code = 'free';
GO
