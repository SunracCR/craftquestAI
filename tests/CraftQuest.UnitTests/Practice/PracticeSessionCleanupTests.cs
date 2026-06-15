using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.Practice;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.UnitTests.Practice;

public class PracticeSessionCleanupTests
{
    [Fact]
    public async Task DeletePracticeDataForQuiz_RemovesSnapshotsBeforeSessions()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var quizId = Guid.NewGuid();
        var questionId = Guid.NewGuid();
        var sessionId = Guid.NewGuid();
        var snapshotId = Guid.NewGuid();

        db.QuestionTypes.Add(new QuestionType
        {
            QuestionTypeId = 1,
            Code = "single_choice",
            Name = "Single choice",
            IsActive = true,
        });
        db.Users.Add(new User
        {
            UserId = userId,
            Email = "cleanup@test.com",
            EmailNormalized = "CLEANUP@TEST.COM",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
        });
        db.Quizzes.Add(new Quiz
        {
            QuizId = quizId,
            CreatedByUserId = userId,
            Title = "Cleanup quiz",
            Visibility = "private",
            PublicationStatus = "draft",
            CreatedAt = DateTime.UtcNow,
        });
        db.Questions.Add(new Question
        {
            QuestionId = questionId,
            QuizId = quizId,
            QuestionTypeId = 1,
            QuestionText = "Q?",
            Points = 1,
            SortOrder = 1,
            ExplanationVisibility = "never",
            ScoringPolicy = "strict",
            ReviewStatus = "approved",
            CreatedByUserId = userId,
            CreatedAt = DateTime.UtcNow,
        });
        db.PracticeSessions.Add(new PracticeSession
        {
            PracticeSessionId = sessionId,
            StudentUserId = userId,
            QuizId = quizId,
            StartedAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
        });
        db.PracticeQuestionSnapshots.Add(new PracticeQuestionSnapshot
        {
            PracticeQuestionSnapshotId = snapshotId,
            PracticeSessionId = sessionId,
            QuestionId = questionId,
            QuestionTypeCodeSnapshot = "single_choice",
            QuestionTextSnapshot = "Q?",
            PointsPossible = 1,
            DisplayOrder = 1,
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        await PracticeSessionCleanup.DeletePracticeDataForQuizAsync(db, quizId);

        Assert.Empty(await db.PracticeSessions.ToListAsync());
        Assert.Empty(await db.PracticeQuestionSnapshots.ToListAsync());
    }

    private static CraftQuestDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<CraftQuestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new CraftQuestDbContext(options);
    }
}
