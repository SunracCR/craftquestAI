using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Models.Offline;
using CraftQuest.Application.Models.Practice;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using CraftQuest.Infrastructure.Services.Offline;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace CraftQuest.UnitTests.Offline;

public class OfflineQuizServiceTests
{
    [Fact]
    public async Task GetOfflinePackageAsync_CapsExpiresAtToPurchaseAccessExpiry()
    {
        await using var db = CreateDb();
        var ownerId = Guid.NewGuid();
        var userId = Guid.NewGuid();
        var quizId = Guid.NewGuid();
        var questionId = Guid.NewGuid();
        var optionAId = Guid.NewGuid();
        var optionBId = Guid.NewGuid();
        var now = DateTime.UtcNow;
        var purchaseExpiry = now.AddDays(5);

        SeedQuizWithQuestion(
            db,
            ownerId,
            userId,
            quizId,
            questionId,
            optionAId,
            optionBId,
            purchaseExpiry);

        var service = CreateService(db, packageTtlDays: 30);
        var package = await service.GetOfflinePackageAsync(userId, quizId);

        Assert.True(package.ExpiresAt <= purchaseExpiry);
        Assert.True(package.ExpiresAt > now);
    }

    [Fact]
    public async Task GetOfflinePackageAsync_LifetimePurchase_UsesFullPackageTtl()
    {
        await using var db = CreateDb();
        var ownerId = Guid.NewGuid();
        var userId = Guid.NewGuid();
        var quizId = Guid.NewGuid();
        var questionId = Guid.NewGuid();
        var optionAId = Guid.NewGuid();
        var optionBId = Guid.NewGuid();
        var now = DateTime.UtcNow;

        SeedQuizWithQuestion(
            db,
            ownerId,
            userId,
            quizId,
            questionId,
            optionAId,
            optionBId,
            purchaseExpiry: now.AddDays(5),
            isLifetimeAccess: true);

        var service = CreateService(db, packageTtlDays: 30);
        var package = await service.GetOfflinePackageAsync(userId, quizId);

        Assert.True(package.ExpiresAt >= now.AddDays(29));
        Assert.True(package.ExpiresAt <= now.AddDays(31));
    }

    private static OfflineQuizService CreateService(
        CraftQuestDbContext db,
        int packageTtlDays)
    {
        return new OfflineQuizService(
            db,
            new FakeBillingService(),
            new FakeMediaService(),
            new FakeAnalyticsService(),
            new OfflinePackageCryptoService(
                Options.Create(new OfflineOptions { PackageTtlDays = packageTtlDays })),
            Options.Create(new OfflineOptions { PackageTtlDays = packageTtlDays }),
            NullLogger<OfflineQuizService>.Instance);
    }

    private static void SeedQuizWithQuestion(
        CraftQuestDbContext db,
        Guid ownerId,
        Guid userId,
        Guid quizId,
        Guid questionId,
        Guid optionAId,
        Guid optionBId,
        DateTime purchaseExpiry,
        bool isLifetimeAccess = false)
    {
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
                UserId = userId,
                Email = "student@test.com",
                EmailNormalized = "STUDENT@TEST.COM",
                Status = "active",
                CreatedAt = now,
            });
        db.QuestionTypes.Add(new QuestionType
        {
            QuestionTypeId = 1,
            Code = "single_choice",
            Name = "Single choice",
            IsActive = true,
        });
        db.Quizzes.Add(new Quiz
        {
            QuizId = quizId,
            CreatedByUserId = ownerId,
            Title = "Prep+ quiz",
            Visibility = "private",
            PublicationStatus = "published",
            RandomizeQuestions = false,
            DefaultRandomizeAnswerOptions = true,
            CreatedAt = now,
            UpdatedAt = now,
        });
        db.QuizAccesses.Add(new QuizAccess
        {
            QuizAccessId = Guid.NewGuid(),
            UserId = userId,
            QuizId = quizId,
            AccessType = "purchase",
            GrantedAt = now.AddDays(-25),
            ExpiresAt = isLifetimeAccess ? null : purchaseExpiry,
            IsLifetimeAccess = isLifetimeAccess,
        });
        db.Questions.Add(new Question
        {
            QuestionId = questionId,
            QuizId = quizId,
            QuestionTypeId = 1,
            QuestionText = "Question?",
            Points = 1,
            SortOrder = 1,
            ExplanationVisibility = "never",
            ScoringPolicy = "strict",
            ReviewStatus = "approved",
            CreatedByUserId = ownerId,
            CreatedAt = now,
            UpdatedAt = now,
        });
        db.QuestionAnswerOptions.AddRange(
            new QuestionAnswerOption
            {
                AnswerOptionId = optionAId,
                QuestionId = questionId,
                StableKey = "A",
                AnswerText = "A",
                DefaultSortOrder = 1,
                IsActive = true,
                CreatedAt = now,
            },
            new QuestionAnswerOption
            {
                AnswerOptionId = optionBId,
                QuestionId = questionId,
                StableKey = "B",
                AnswerText = "B",
                DefaultSortOrder = 2,
                IsActive = true,
                CreatedAt = now,
            });
        db.QuestionCorrectAnswerOptions.Add(new QuestionCorrectAnswerOption
        {
            QuestionId = questionId,
            AnswerOptionId = optionAId,
        });

        db.SaveChanges();
    }

    private static CraftQuestDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<CraftQuestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new CraftQuestDbContext(options);
    }

    private sealed class FakeBillingService : IBillingService
    {
        public Task EnsureCanDownloadOfflineAsync(
            Guid userId,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task<OfflineEntitlementsDto> GetOfflineEntitlementsAsync(
            Guid userId,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(new OfflineEntitlementsDto
            {
                CanDownloadOffline = true,
                MaxOfflineQuizzes = 10,
                MaxOfflineStorageMb = 512,
            });

        public Task<UserBillingDto> GetMyBillingAsync(
            Guid userId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task<IReadOnlyList<PurchaseHistoryItemDto>> GetMyPurchasesAsync(
            Guid userId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task EnsureCanCreateQuizAsync(
            Guid userId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task EnsureCanModifyOwnedQuizzesAsync(
            Guid userId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task EnsureCanAddQuestionAsync(
            Guid userId,
            Guid quizId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task<QuizQuestionCapacityDto> GetQuizQuestionCapacityAsync(
            Guid userId,
            Guid quizId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task EnsureCanCreateShareCodeAsync(
            Guid userId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task EnsureCanRedeemSharedQuizAsync(
            Guid userId,
            Guid quizId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task EnsureCanInviteUserToQuizAsync(
            Guid userId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task AssignFreePlanAsync(
            Guid userId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task EnsureHasAiCreditsAsync(
            Guid userId,
            int amount,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task ConsumeAiCreditsAsync(
            Guid userId,
            int amount,
            string? referenceType,
            Guid? referenceId,
            CancellationToken cancellationToken = default,
            bool saveImmediately = true) =>
            throw new NotImplementedException();

        public Task<int> GrantPurchasedAiCreditsAsync(
            Guid userId,
            int amount,
            Guid purchaseId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task ActivatePlanAsync(
            Guid userId,
            string planCode,
            string providerCode,
            string? providerSubscriptionId,
            SubscriptionActivationOptions? options = null,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task<CancelAutoRenewResponse> CancelAutoRenewAsync(
            Guid userId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task<ReactivateAutoRenewResponse> ReactivateAutoRenewAsync(
            Guid userId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task CancelSubscriptionAsync(
            Guid userId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task<bool> IsSubscriptionExpiringAsync(
            Guid userId,
            int withinDays = 7,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task<int> ProcessExpiredSubscriptionsAsync(
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task RenewSubscriptionPeriodAsync(
            string providerSubscriptionId,
            string providerCode,
            DateTime? periodEnd,
            string? paymentTransactionId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task RevokeSubscriptionImmediatelyAsync(
            string providerSubscriptionId,
            string providerCode,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();
    }

    private sealed class FakeMediaService : IMediaService
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
            throw new NotImplementedException();
    }

    private sealed class FakeAnalyticsService : IAnalyticsService
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
}
