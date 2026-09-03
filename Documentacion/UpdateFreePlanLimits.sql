-- Plan Free: 2 cuestionarios y 25 preguntas por cuestionario.
-- Afecta creación, importación Excel y generación IA (vía billing.Plans).
UPDATE billing.Plans
SET
    MaxQuizzes = 2,
    MaxQuestionsPerQuiz = 25
WHERE Code = 'free';
GO
