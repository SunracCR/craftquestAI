-- Tracks whether the student enabled the elapsed-time clock for this practice session.
IF COL_LENGTH('practice.PracticeSessions', 'ShowElapsedTimer') IS NULL
BEGIN
    ALTER TABLE practice.PracticeSessions
    ADD ShowElapsedTimer BIT NOT NULL
        CONSTRAINT DF_PracticeSessions_ShowElapsedTimer DEFAULT (0);
END
GO
