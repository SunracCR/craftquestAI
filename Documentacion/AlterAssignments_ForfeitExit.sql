/* Forfeit-on-exit policy for class assignments (only meaningful with MaxAttempts > 0). */
IF COL_LENGTH('teacher.Assignments', 'ForfeitExitCountsAsAttempt') IS NULL
BEGIN
    ALTER TABLE teacher.Assignments
        ADD ForfeitExitCountsAsAttempt BIT NOT NULL
            CONSTRAINT DF_Assignments_ForfeitExitCountsAsAttempt DEFAULT (0);
END
GO

/* Allow forfeited sessions when the student leaves mid-attempt. */
IF EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = 'CK_PracticeSessions_Status'
        AND parent_object_id = OBJECT_ID('practice.PracticeSessions'))
BEGIN
    ALTER TABLE practice.PracticeSessions
        DROP CONSTRAINT CK_PracticeSessions_Status;
END
GO

ALTER TABLE practice.PracticeSessions
    ADD CONSTRAINT CK_PracticeSessions_Status
        CHECK (Status IN ('in_progress', 'finished', 'abandoned', 'expired', 'forfeited'));
GO
