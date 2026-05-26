/* Progress metadata for AI quiz generation jobs (Fase 1–2 bandeja + biblioteca) */

IF COL_LENGTH('ai.AiJobs', 'Stage') IS NULL
    ALTER TABLE ai.AiJobs ADD Stage NVARCHAR(40) NULL;
GO

IF COL_LENGTH('ai.AiJobs', 'ProgressPercent') IS NULL
    ALTER TABLE ai.AiJobs ADD ProgressPercent INT NULL;
GO

IF COL_LENGTH('ai.AiJobs', 'StartedAt') IS NULL
    ALTER TABLE ai.AiJobs ADD StartedAt DATETIME2(7) NULL;
GO
