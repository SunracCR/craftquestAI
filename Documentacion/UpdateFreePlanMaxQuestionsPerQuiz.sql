-- Free plan: raise per-quiz question limit to 65.
UPDATE billing.Plans
SET MaxQuestionsPerQuiz = 65
WHERE Code = 'free';
GO
