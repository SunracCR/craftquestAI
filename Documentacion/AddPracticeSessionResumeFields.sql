-- Resume / pause practice session (continue later).
IF COL_LENGTH('practice.PracticeSessions', 'CurrentQuestionIndex') IS NULL
BEGIN
    ALTER TABLE practice.PracticeSessions ADD CurrentQuestionIndex INT NULL;
END
GO

IF COL_LENGTH('practice.PracticeSessions', 'ElapsedSecondsBeforePause') IS NULL
BEGIN
    ALTER TABLE practice.PracticeSessions ADD ElapsedSecondsBeforePause INT NOT NULL
        CONSTRAINT DF_PracticeSessions_ElapsedSecondsBeforePause DEFAULT(0);
END
GO

IF COL_LENGTH('practice.PracticeSessions', 'PausedAt') IS NULL
BEGIN
    ALTER TABLE practice.PracticeSessions ADD PausedAt DATETIME2(7) NULL;
END
GO

IF COL_LENGTH('practice.PracticeSessions', 'LastActivityAt') IS NULL
BEGIN
    ALTER TABLE practice.PracticeSessions ADD LastActivityAt DATETIME2(7) NULL;
END
GO

UPDATE practice.PracticeSessions
SET LastActivityAt = COALESCE(LastActivityAt, StartedAt)
WHERE Status = 'in_progress' AND LastActivityAt IS NULL;
GO
