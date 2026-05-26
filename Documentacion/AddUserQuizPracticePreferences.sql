IF OBJECT_ID('practice.UserQuizPracticePreferences', 'U') IS NULL
BEGIN
    CREATE TABLE practice.UserQuizPracticePreferences (
        UserId UNIQUEIDENTIFIER NOT NULL,
        QuizId UNIQUEIDENTIFIER NOT NULL,
        RandomizeQuestions BIT NOT NULL
            CONSTRAINT DF_UserQuizPracticePreferences_RandomizeQuestions DEFAULT (0),
        ShowElapsedTimer BIT NOT NULL
            CONSTRAINT DF_UserQuizPracticePreferences_ShowElapsedTimer DEFAULT (1),
        UpdatedAt DATETIME2(7) NOT NULL
            CONSTRAINT DF_UserQuizPracticePreferences_UpdatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_UserQuizPracticePreferences PRIMARY KEY (UserId, QuizId),
        CONSTRAINT FK_UserQuizPracticePreferences_Users
            FOREIGN KEY (UserId) REFERENCES core.Users(UserId) ON DELETE CASCADE,
        CONSTRAINT FK_UserQuizPracticePreferences_Quizzes
            FOREIGN KEY (QuizId) REFERENCES quiz.Quizzes(QuizId) ON DELETE CASCADE
    );
END
GO
