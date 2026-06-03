/* Créditos IA alineados con generaciones máx. (40 preg. = 6 créditos c/u):
   Pro: 25 × 6 = 150 | Teacher: 60 × 6 = 360
   Ejecutar en bases ya desplegadas. Nuevos despliegues: MERGE en DDL v4. */

SET QUOTED_IDENTIFIER ON;
GO

UPDATE billing.Plans
SET MonthlyAiCredits = 20
WHERE Code = N'free';

UPDATE billing.Plans
SET MonthlyAiCredits = 150
WHERE Code = N'pro';

UPDATE billing.Plans
SET MonthlyAiCredits = 360
WHERE Code = N'teacher';
GO

SELECT Code, Name, MonthlyAiCredits, MonthlyShareCodes
FROM billing.Plans
WHERE Code IN (N'free', N'pro', N'teacher', N'institution')
ORDER BY MonthlyPrice, Code;
GO
