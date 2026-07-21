-- Adds per-plan cap for AI quiz generation question count.
IF COL_LENGTH('billing.Plans', 'MaxQuestionsPerAiGeneration') IS NULL
BEGIN
    ALTER TABLE billing.Plans
        ADD MaxQuestionsPerAiGeneration INT NULL;
END
GO

UPDATE billing.Plans SET MaxQuestionsPerAiGeneration = 25 WHERE Code = 'free';
UPDATE billing.Plans SET MaxQuestionsPerAiGeneration = 80 WHERE Code = 'pro';
UPDATE billing.Plans SET MaxQuestionsPerAiGeneration = 100 WHERE Code = 'teacher';
UPDATE billing.Plans SET MaxQuestionsPerAiGeneration = 120 WHERE Code = 'institution';
GO

SELECT Code, MaxQuestionsPerQuiz, MaxQuestionsPerAiGeneration, MonthlyAiCredits
FROM billing.Plans
ORDER BY PlanId;
