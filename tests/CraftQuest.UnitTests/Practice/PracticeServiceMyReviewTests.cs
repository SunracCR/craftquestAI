using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using CraftQuest.Infrastructure.Services.Practice;
using CraftQuest.UnitTests.Billing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace CraftQuest.UnitTests.Practice;

public class PracticeServiceMyReviewTests
{
    [Fact]
    public async Task GetMySessionReviewAsync_OwnFinishedSession_AllowsReviewWhenPurchaseAccessExpired()
    {
        await using var db = CreateDb();
        var (studentId, sessionId) = await SeedFinishedPrepPlusSessionAsync(
            db,
            purchaseExpiresAt: DateTime.UtcNow.AddDays(-1));

        var service = CreateService(db);
        var review = await service.GetMySessionReviewAsync(studentId, sessionId);

        Assert.Equal(sessionId, review.PracticeSessionId);
        Assert.Single(review.Questions);
    }

    [Fact]
    public async Task GetMySessionReviewAsync_OtherUser_ThrowsForbidden()
    {
        await using var db = CreateDb();
        var (studentId, sessionId) = await SeedFinishedPrepPlusSessionAsync(
            db,
            purchaseExpiresAt: DateTime.UtcNow.AddDays(10));
        var otherUserId = Guid.NewGuid();
        db.Users.Add(new User
        {
            UserId = otherUserId,
            Email = "other@test.com",
            EmailNormalized = "OTHER@TEST.COM",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        var service = CreateService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.GetMySessionReviewAsync(otherUserId, sessionId));

        Assert.Equal(403, ex.StatusCode);
        Assert.Contains("permission", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    private static PracticeService CreateService(CraftQuestDbContext db)
    {
        var shareCodeService = new ShareCodeService(
            db,
            BillingTestHelpers.CreateService(db),
            new ShareCodeServiceTestsStubClassService(),
            new ShareCodeServiceTestsStubNotificationService(),
            NullLogger<ShareCodeService>.Instance,
            Options.Create(new JoinLinkOptions
            {
                LinkBaseUrl = "https://api.craftquestai.com",
            }));

        return new PracticeService(
            db,
            shareCodeService,
            new StubAnalyticsService(),
            new StubMediaService(),
            new StubPracticeSnapshotDeferredWriter(),
            new PrepPlusQuestionBankService(db),
            Options.Create(new PracticeOptions()),
            NullLogger<PracticeService>.Instance);
    }

    private static async Task<(Guid StudentId, Guid SessionId)> SeedFinishedPrepPlusSessionAsync(
        CraftQuestDbContext db,
        DateTime purchaseExpiresAt)
    {
        var ownerId = Guid.NewGuid();
        var studentId = Guid.NewGuid();
        var quizId = Guid.NewGuid();
        var sessionId = Guid.NewGuid();
        var questionSnapshotId = Guid.NewGuid();
        var answerSnapshotId = Guid.NewGuid();
        var now = DateTime.UtcNow;

        db.Users.AddRange(
            new User
            {
                UserId = ownerId,
                Email = "owner@test.com",
                EmailNormalized = "OWNER@TEST.COM",
                Status = "active",
                CreatedAt = now,
            },
            new User
            {
                UserId = studentId,
                Email = "student@test.com",
                EmailNormalized = "STUDENT@TEST.COM",
                DisplayName = "Student",
                Status = "active",
                CreatedAt = now,
            });
        db.Quizzes.Add(new Quiz
        {
            QuizId = quizId,
            CreatedByUserId = ownerId,
            Title = "Prep+ curated quiz",
            Visibility = "curated",
            PublicationStatus = "published",
            IsCurated = true,
            CreatedAt = now,
        });
        db.QuizAccesses.Add(new QuizAccess
        {
            QuizAccessId = Guid.NewGuid(),
            UserId = studentId,
            QuizId = quizId,
            AccessType = "purchase",
            GrantedAt = now.AddDays(-30),
            ExpiresAt = purchaseExpiresAt,
            IsLifetimeAccess = false,
        });
        db.PracticeSessions.Add(new PracticeSession
        {
            PracticeSessionId = sessionId,
            StudentUserId = studentId,
            QuizId = quizId,
            StartedAt = now.AddMinutes(-20),
            FinishedAt = now.AddMinutes(-5),
            DurationSeconds = 900,
            ScoreObtained = 1,
            ScorePossible = 1,
            CorrectAnswers = 1,
            IncorrectAnswers = 0,
            OmittedAnswers = 0,
            Status = "finished",
            CreatedAt = now.AddMinutes(-20),
        });
        db.PracticeQuestionSnapshots.Add(new PracticeQuestionSnapshot
        {
            PracticeQuestionSnapshotId = questionSnapshotId,
            PracticeSessionId = sessionId,
            QuestionId = Guid.NewGuid(),
            QuestionTypeCodeSnapshot = "single_choice",
            QuestionTextSnapshot = "Sample question",
            PointsPossible = 1,
            PointsAwarded = 1,
            DisplayOrder = 1,
            AnswerStatus = "correct",
            IsCorrect = true,
            CreatedAt = now.AddMinutes(-10),
            AnswerOptionSnapshots =
            [
                new PracticeAnswerOptionSnapshot
                {
                    PracticeAnswerOptionSnapshotId = answerSnapshotId,
                    AnswerOptionId = Guid.NewGuid(),
                    DisplayOrder = 1,
                    DisplayLabel = "A",
                    AnswerTextSnapshot = "Answer A",
                    IsCorrectSnapshot = true,
                    WasSelected = true,
                    CreatedAt = now.AddMinutes(-10),
                },
            ],
        });
        await db.SaveChangesAsync();

        return (studentId, sessionId);
    }

    private static CraftQuestDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<CraftQuestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new CraftQuestDbContext(options);
    }

    private sealed class StubAnalyticsService : IAnalyticsService
    {
        public Task RecordFinishedPracticeSessionAsync(
            PracticeSession session,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task<Application.Models.Analytics.QuizAnalyticsDto> GetQuizAnalyticsAsync(
            Guid teacherUserId,
            Guid quizId,
            Guid? classId = null,
            Guid? assignmentId = null,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();
    }

    private sealed class StubMediaService : IMediaService
    {
        public string BuildPublicUrl(Guid mediaAssetId) =>
            $"https://example.com/media/{mediaAssetId}";

        public Task<Application.Models.Media.MediaAssetDto> UploadImageAsync(
            Guid userId,
            Stream content,
            string fileName,
            string contentType,
            long fileSize,
            string? altText = null,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task<(Stream Stream, string ContentType, string FileName)> OpenReadAsync(
            Guid mediaAssetId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task<bool> ExistsAsync(
            Guid mediaAssetId,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(false);
    }

    private sealed class StubPracticeSnapshotDeferredWriter : IPracticeSnapshotDeferredWriter
    {
        public void EnqueueRemainingAnswerOptions(
            Guid practiceSessionId,
            IReadOnlyList<PracticeAnswerOptionSnapshot> answerOptions)
        {
        }
    }

    private sealed class ShareCodeServiceTestsStubClassService : IClassService
    {
        public Task<bool> IsActiveClassMemberAsync(
            Guid userId,
            Guid classId,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(true);

        public Task<IReadOnlyList<Application.Models.Teacher.TeacherClassSummaryDto>> ListTeacherClassesAsync(
            Guid teacherUserId,
            string? status = "active",
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task<Application.Models.Teacher.TeacherClassSummaryDto> CreateAsync(
            Guid teacherUserId,
            Application.Models.Teacher.CreateClassRequest request,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task UpdateAsync(
            Guid teacherUserId,
            Guid classId,
            Application.Models.Teacher.UpdateClassRequest request,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task ArchiveAsync(
            Guid teacherUserId,
            Guid classId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task RestoreAsync(
            Guid teacherUserId,
            Guid classId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task DeleteAsync(
            Guid teacherUserId,
            Guid classId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task<Application.Models.Teacher.ClassDetailDto> GetDetailAsync(
            Guid teacherUserId,
            Guid classId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task<Application.Models.Teacher.ClassMemberDto> AddMemberByEmailAsync(
            Guid teacherUserId,
            Guid classId,
            string email,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task ApproveMemberAsync(
            Guid teacherUserId,
            Guid classId,
            Guid userId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task RemoveMemberAsync(
            Guid teacherUserId,
            Guid classId,
            Guid userId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task EnsureTeacherOwnsClassAsync(
            Guid teacherUserId,
            Guid classId,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;
    }

    private sealed class ShareCodeServiceTestsStubNotificationService : INotificationService
    {
        public Task NotifyAsync(
            Guid userId,
            string type,
            Application.Models.Notifications.NotificationPayload payload,
            string? dedupKey = null,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task NotifyManyAsync(
            IReadOnlyList<Guid> userIds,
            string type,
            Application.Models.Notifications.NotificationPayload payload,
            Func<Guid, string?>? dedupKeyFactory = null,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task EnqueueFanOutAsync(
            string eventType,
            string payloadJson,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task<Application.Models.Notifications.NotificationListResultDto> ListAsync(
            Guid userId,
            string? cursor,
            int limit,
            bool unreadOnly,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task<int> CountUnreadAsync(Guid userId, CancellationToken cancellationToken = default) =>
            Task.FromResult(0);

        public Task MarkReadAsync(
            Guid userId,
            Guid notificationId,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task MarkAllReadAsync(Guid userId, CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task RegisterDeviceTokenAsync(
            Guid userId,
            Application.Models.Notifications.RegisterDeviceTokenRequest request,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task RemoveDeviceTokenAsync(
            Guid userId,
            string token,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task<Application.Models.Notifications.NotificationPreferencesDto> GetPreferencesAsync(
            Guid userId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task UpdatePreferencesAsync(
            Guid userId,
            Application.Models.Notifications.UpdateNotificationPreferencesRequest request,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;
    }
}
