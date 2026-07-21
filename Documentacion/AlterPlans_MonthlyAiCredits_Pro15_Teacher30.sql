/* Reduce generaciones mensuales objetivo (40 preg. = 6 créditos c/u):
   Pro: 15 × 6 = 90 | Teacher: 30 × 6 = 180
   Ejecutar en bases ya desplegadas con 150/360. */

SET QUOTED_IDENTIFIER ON;
GO

UPDATE billing.Plans
SET MonthlyAiCredits = 90
WHERE Code = N'pro';

UPDATE billing.Plans
SET MonthlyAiCredits = 180
WHERE Code = N'teacher';
GO

SELECT Code, Name, MonthlyAiCredits, MaxQuestionsPerAiGeneration, MonthlyShareCodes
FROM billing.Plans
WHERE Code IN (N'free', N'pro', N'teacher', N'institution')
ORDER BY MonthlyPrice, Code;
GO
