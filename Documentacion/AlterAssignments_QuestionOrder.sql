/* Assignment-level question order policy (class tasks only). */
IF COL_LENGTH('teacher.Assignments', 'RandomizeQuestions') IS NULL
BEGIN
    ALTER TABLE teacher.Assignments
        ADD RandomizeQuestions BIT NOT NULL
            CONSTRAINT DF_Assignments_RandomizeQuestions DEFAULT (0);
END
GO

IF COL_LENGTH('teacher.Assignments', 'AllowStudentRandomizeQuestions') IS NULL
BEGIN
    ALTER TABLE teacher.Assignments
        ADD AllowStudentRandomizeQuestions BIT NOT NULL
            CONSTRAINT DF_Assignments_AllowStudentRandomizeQuestions DEFAULT (0);
END
GO

/* Align existing assignments with their quiz default order policy. */
UPDATE a
SET a.RandomizeQuestions = q.RandomizeQuestions
FROM teacher.Assignments a
INNER JOIN quiz.Quizzes q ON q.QuizId = a.QuizId;
GO
