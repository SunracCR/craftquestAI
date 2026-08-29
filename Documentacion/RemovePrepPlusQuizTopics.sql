/* Remove nested QuizTopics taxonomy (chapters-only custom practice). */

IF EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_Questions_QuizTopics'
      AND parent_object_id = OBJECT_ID('quiz.Questions'))
BEGIN
    ALTER TABLE quiz.Questions DROP CONSTRAINT FK_Questions_QuizTopics;
END
GO

IF COL_LENGTH('quiz.Questions', 'QuizTopicId') IS NOT NULL
BEGIN
    DROP INDEX IF EXISTS IX_Questions_QuizTopicId ON quiz.Questions;

    ALTER TABLE quiz.Questions DROP COLUMN QuizTopicId;
END
GO

IF OBJECT_ID('quiz.QuizTopics', 'U') IS NOT NULL
BEGIN
    DROP TABLE quiz.QuizTopics;
END
GO
