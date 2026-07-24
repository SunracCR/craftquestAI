-- Offline quiz support: plan limits + practice session client id for idempotent sync.
IF COL_LENGTH('billing.Plans', 'MaxOfflineQuizzes') IS NULL
BEGIN
    ALTER TABLE billing.Plans ADD MaxOfflineQuizzes INT NULL;
END
GO

IF COL_LENGTH('billing.Plans', 'MaxOfflineStorageMb') IS NULL
BEGIN
    ALTER TABLE billing.Plans ADD MaxOfflineStorageMb INT NULL;
END
GO

UPDATE billing.Plans SET MaxOfflineQuizzes = 0, MaxOfflineStorageMb = 0 WHERE Code = 'free';
UPDATE billing.Plans SET MaxOfflineQuizzes = 10, MaxOfflineStorageMb = 500 WHERE Code = 'pro';
UPDATE billing.Plans SET MaxOfflineQuizzes = 25, MaxOfflineStorageMb = 1024 WHERE Code = 'teacher';
UPDATE billing.Plans SET MaxOfflineQuizzes = NULL, MaxOfflineStorageMb = 2048 WHERE Code = 'institution';
GO

IF COL_LENGTH('practice.PracticeSessions', 'ClientSessionId') IS NULL
BEGIN
    ALTER TABLE practice.PracticeSessions ADD ClientSessionId UNIQUEIDENTIFIER NULL;
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_PracticeSessions_ClientSessionId'
      AND object_id = OBJECT_ID('practice.PracticeSessions'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX IX_PracticeSessions_ClientSessionId
        ON practice.PracticeSessions (ClientSessionId)
        WHERE ClientSessionId IS NOT NULL;
END
GO
