-- Obsoleto: usar UpdateFreePlanLimits.sql (2 cuestionarios, 25 preguntas).
-- Mantenido por referencia en checklist histórico.
UPDATE billing.Plans
SET
    MaxQuizzes = 2,
    MaxQuestionsPerQuiz = 25
WHERE Code = 'free';
GO
