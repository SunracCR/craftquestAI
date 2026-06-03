-- Plan Free: 2 cuestionarios y 50 preguntas por cuestionario.
-- Afecta creación, importación Excel y generación IA (vía billing.Plans).
UPDATE billing.Plans
SET
    MaxQuizzes = 2,
    MaxQuestionsPerQuiz = 50
WHERE Code = 'free';
GO
