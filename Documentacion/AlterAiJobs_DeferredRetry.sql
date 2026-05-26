/* Deferred retry + error metadata for AI quiz generation jobs */

IF COL_LENGTH('ai.AiJobs', 'ErrorCode') IS NULL
    ALTER TABLE ai.AiJobs ADD ErrorCode NVARCHAR(80) NULL;
GO

IF COL_LENGTH('ai.AiJobs', 'NextRetryAt') IS NULL
    ALTER TABLE ai.AiJobs ADD NextRetryAt DATETIME2(7) NULL;
GO

IF COL_LENGTH('ai.AiJobs', 'RetryAttempt') IS NULL
    ALTER TABLE ai.AiJobs ADD RetryAttempt INT NOT NULL CONSTRAINT DF_AiJobs_RetryAttempt DEFAULT(0);
GO

IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = 'CK_AiJobs_Status' AND parent_object_id = OBJECT_ID('ai.AiJobs'))
BEGIN
    ALTER TABLE ai.AiJobs DROP CONSTRAINT CK_AiJobs_Status;
END
GO

ALTER TABLE ai.AiJobs ADD CONSTRAINT CK_AiJobs_Status
    CHECK (Status IN ('pending','processing','pending_retry','completed','failed','cancelled'));
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AiJobs_PendingRetry' AND object_id = OBJECT_ID('ai.AiJobs'))
BEGIN
    SET QUOTED_IDENTIFIER ON;
    CREATE INDEX IX_AiJobs_PendingRetry ON ai.AiJobs (Status, NextRetryAt)
    WHERE Status IN ('pending','pending_retry');
END
GO
