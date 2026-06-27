using CraftQuest.Application.Constants;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Notifications;
using CraftQuest.Application.Models.Sharing;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using CraftQuest.UnitTests.Billing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace CraftQuest.UnitTests.Sharing;

public class ShareCodeServiceTests
{
    [Fact]
    public async Task CreateShareCode_SecondCall_ReturnsSameCode()
    {
        await using var db = CreateDb();
        var (ownerId, quizId) = await SeedOwnerAndPublishedQuizAsync(db);

        var billing = BillingTestHelpers.CreateService(db);
        var service = CreateService(db, billing);

        var first = await service.CreateShareCodeAsync(
            ownerId,
            quizId,
            new CreateShareCodeRequest());

        var second = await service.CreateShareCodeAsync(
            ownerId,
            quizId,
            new CreateShareCodeRequest());

        Assert.True(second.IsExisting);
        Assert.Equal(first.Code, second.Code);
        Assert.Equal(1, await db.ShareCodes.CountAsync(s => s.QuizId == quizId));
    }

    [Fact]
    public async Task RedeemAsync_FreePlanThirdDistinctQuiz_ThrowsSlotLimit()
    {
        await using var db = CreateDb();
        var ownerId = Guid.NewGuid();
        var studentId = Guid.NewGuid();
        await SeedUsersAndFreePlanAsync(db, ownerId, studentId);

        var quizIds = new List<Guid>();
        for (var i = 0; i < 3; i++)
        {
            var quizId = Guid.NewGuid();
            quizIds.Add(quizId);
            db.Quizzes.Add(new Quiz
            {
                QuizId = quizId,
                CreatedByUserId = ownerId,
                Title = $"Quiz {i}",
                Visibility = "private",
                PublicationStatus = "published",
                CreatedAt = DateTime.UtcNow,
            });
            db.ShareCodes.Add(new ShareCode
            {
                ShareCodeId = Guid.NewGuid(),
                Code = $"CQ-00000{i}",
                QuizId = quizId,
                CreatedByUserId = ownerId,
                CodeType = "class_capacity",
                MaxRedemptions = int.MaxValue,
                Status = "active",
                AccessPolicy = "guest_open",
                CreatedAt = DateTime.UtcNow,
            });
        }

        await db.SaveChangesAsync();

        var billing = BillingTestHelpers.CreateService(db);
        var service = CreateService(db, billing);

        await service.RedeemAsync(studentId, new RedeemShareCodeRequest { Code = "CQ-000000" });
        await service.RedeemAsync(studentId, new RedeemShareCodeRequest { Code = "CQ-000001" });

        var ex = await Assert.ThrowsAsync<CraftQuest.Application.Exceptions.AppException>(() =>
            service.RedeemAsync(studentId, new RedeemShareCodeRequest { Code = "CQ-000002" }));

        Assert.Equal("SHARED_QUIZ_SLOT_LIMIT", ex.ErrorCode);
    }

    [Fact]
    public async Task RedeemAsync_AfterRemoveAccessibleQuiz_FreeCanRedeemAgain()
    {
        await using var db = CreateDb();
        var ownerId = Guid.NewGuid();
        var studentId = Guid.NewGuid();
        await SeedUsersAndFreePlanAsync(db, ownerId, studentId);

        var quizIds = new List<Guid>();
        for (var i = 0; i < 3; i++)
        {
            var quizId = Guid.NewGuid();
            quizIds.Add(quizId);
            db.Quizzes.Add(new Quiz
            {
                QuizId = quizId,
                CreatedByUserId = ownerId,
                Title = $"Quiz {i}",
                Visibility = "private",
                PublicationStatus = "published",
                CreatedAt = DateTime.UtcNow,
            });
            db.ShareCodes.Add(new ShareCode
            {
                ShareCodeId = Guid.NewGuid(),
                Code = $"CQ-10000{i}",
                QuizId = quizId,
                CreatedByUserId = ownerId,
                CodeType = "class_capacity",
                MaxRedemptions = int.MaxValue,
                Status = "active",
                AccessPolicy = "guest_open",
                CreatedAt = DateTime.UtcNow,
            });
        }

        await db.SaveChangesAsync();

        var billing = BillingTestHelpers.CreateService(db);
        var service = CreateService(db, billing);

        await service.RedeemAsync(studentId, new RedeemShareCodeRequest { Code = "CQ-100000" });
        await service.RedeemAsync(studentId, new RedeemShareCodeRequest { Code = "CQ-100001" });

        await service.RemoveAccessibleQuizAsync(studentId, quizIds[0]);

        var result = await service.RedeemAsync(
            studentId,
            new RedeemShareCodeRequest { Code = "CQ-100002" });

        Assert.Equal(quizIds[2], result.QuizId);
    }

    [Fact]
    public async Task RedeemAsync_OwnQuiz_ThrowsCannotRedeemOwnQuiz()
    {
        await using var db = CreateDb();
        var (ownerId, quizId) = await SeedOwnerAndPublishedQuizAsync(db);

        db.ShareCodes.Add(new ShareCode
        {
            ShareCodeId = Guid.NewGuid(),
            Code = "CQ-OWN001",
            QuizId = quizId,
            CreatedByUserId = ownerId,
            CodeType = "class_capacity",
            MaxRedemptions = int.MaxValue,
            Status = "active",
            AccessPolicy = "guest_open",
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        var billing = BillingTestHelpers.CreateService(db);
        var service = CreateService(db, billing);

        var ex = await Assert.ThrowsAsync<CraftQuest.Application.Exceptions.AppException>(() =>
            service.RedeemAsync(ownerId, new RedeemShareCodeRequest { Code = "CQ-OWN001" }));

        Assert.Equal("CANNOT_REDEEM_OWN_QUIZ", ex.ErrorCode);
    }

    [Fact]
    public async Task RedeemAsync_AlreadyInSharedList_ReturnsFlagWithoutDuplicate()
    {
        await using var db = CreateDb();
        var ownerId = Guid.NewGuid();
        var studentId = Guid.NewGuid();
        await SeedUsersAndFreePlanAsync(db, ownerId, studentId);

        var quizId = Guid.NewGuid();
        db.Quizzes.Add(new Quiz
        {
            QuizId = quizId,
            CreatedByUserId = ownerId,
            Title = "Shared quiz",
            Visibility = "private",
            PublicationStatus = "published",
            CreatedAt = DateTime.UtcNow,
        });
        var shareCodeId = Guid.NewGuid();
        db.ShareCodes.Add(new ShareCode
        {
            ShareCodeId = shareCodeId,
            Code = "CQ-DUP001",
            QuizId = quizId,
            CreatedByUserId = ownerId,
            CodeType = "class_capacity",
            MaxRedemptions = int.MaxValue,
            Status = "active",
            AccessPolicy = "guest_open",
            CreatedAt = DateTime.UtcNow,
        });
        db.QuizAccesses.Add(new QuizAccess
        {
            QuizAccessId = Guid.NewGuid(),
            UserId = studentId,
            QuizId = quizId,
            AccessType = "redeemed",
            GrantedByShareCodeId = shareCodeId,
            GrantedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        var billing = BillingTestHelpers.CreateService(db);
        var service = CreateService(db, billing);

        var result = await service.RedeemAsync(
            studentId,
            new RedeemShareCodeRequest { Code = "CQ-DUP001" });

        Assert.True(result.AlreadyInSharedList);
        Assert.Equal(1, await db.QuizAccesses.CountAsync(a => a.UserId == studentId));
    }

    [Fact]
    public async Task InviteUsersByEmailAsync_ProOwner_InvitesRegisteredUser()
    {
        await using var db = CreateDb();
        var ownerId = Guid.NewGuid();
        var inviteeId = Guid.NewGuid();
        db.Users.AddRange(
            new User
            {
                UserId = ownerId,
                Email = "pro@test.com",
                PasswordHash = [1],
                DisplayName = "Pro Owner",
                Status = "active",
                CreatedAt = DateTime.UtcNow,
            },
            new User
            {
                UserId = inviteeId,
                Email = "invitee@test.com",
                PasswordHash = [1],
                DisplayName = "Invitee",
                Status = "active",
                CreatedAt = DateTime.UtcNow,
            });

        db.Plans.AddRange(
            new Plan { PlanId = 1, Code = "free", Name = "Free", IsActive = true },
            new Plan { PlanId = 2, Code = "pro", Name = "Pro", IsActive = true });

        db.UserSubscriptions.Add(new UserSubscription
        {
            UserSubscriptionId = Guid.NewGuid(),
            UserId = ownerId,
            PlanId = 2,
            Status = "active",
            StartedAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
        });

        db.UserSubscriptions.Add(new UserSubscription
        {
            UserSubscriptionId = Guid.NewGuid(),
            UserId = inviteeId,
            PlanId = 1,
            Status = "active",
            StartedAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
        });

        var quizId = Guid.NewGuid();
        db.Quizzes.Add(new Quiz
        {
            QuizId = quizId,
            CreatedByUserId = ownerId,
            Title = "Quiz",
            Visibility = "private",
            PublicationStatus = "published",
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        var billing = BillingTestHelpers.CreateService(db);
        var service = CreateService(db, billing);

        var result = await service.InviteUsersByEmailAsync(
            ownerId,
            quizId,
            new InviteUsersRequest { Emails = ["invitee@test.com"] });

        Assert.Single(result.Results);
        Assert.Equal("invited", result.Results[0].Outcome);
        Assert.Equal(1, await db.QuizAccesses.CountAsync(a => a.UserId == inviteeId));
    }

    [Fact]
    public async Task InviteUsersByEmailAsync_FreeOwner_ThrowsNotAllowed()
    {
        await using var db = CreateDb();
        var (ownerId, quizId) = await SeedOwnerAndPublishedQuizAsync(db);
        var billing = BillingTestHelpers.CreateService(db);
        var service = CreateService(db, billing);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.InviteUsersByEmailAsync(
                ownerId,
                quizId,
                new InviteUsersRequest { Emails = ["someone@test.com"] }));

        Assert.Equal("DIRECT_INVITE_NOT_ALLOWED", ex.ErrorCode);
    }

    private static CraftQuestDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<CraftQuestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new CraftQuestDbContext(options);
    }

    private static async Task<(Guid OwnerId, Guid QuizId)> SeedOwnerAndPublishedQuizAsync(
        CraftQuestDbContext db)
    {
        var ownerId = Guid.NewGuid();
        db.Users.Add(new User
        {
            UserId = ownerId,
            Email = "owner@test.com",
            PasswordHash = [1],
            DisplayName = "Owner",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
        });

        var freePlan = new Plan
        {
            PlanId = 1,
            Code = "free",
            Name = "Free",
            IsActive = true,
            MonthlyShareCodes = 2,
        };
        db.Plans.Add(freePlan);
        db.UserSubscriptions.Add(new UserSubscription
        {
            UserSubscriptionId = Guid.NewGuid(),
            UserId = ownerId,
            PlanId = 1,
            Status = "active",
            StartedAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
        });

        var quizId = Guid.NewGuid();
        db.Quizzes.Add(new Quiz
        {
            QuizId = quizId,
            CreatedByUserId = ownerId,
            Title = "Shared quiz",
            Visibility = "private",
            PublicationStatus = "published",
            CreatedAt = DateTime.UtcNow,
        });

        await db.SaveChangesAsync();
        return (ownerId, quizId);
    }

    private static async Task SeedUsersAndFreePlanAsync(
        CraftQuestDbContext db,
        Guid ownerId,
        Guid studentId)
    {
        db.Users.AddRange(
            new User
            {
                UserId = ownerId,
                Email = "owner@test.com",
                PasswordHash = [1],
                DisplayName = "Owner",
                Status = "active",
                CreatedAt = DateTime.UtcNow,
            },
            new User
            {
                UserId = studentId,
                Email = "student@test.com",
                PasswordHash = [1],
                DisplayName = "Student",
                Status = "active",
                CreatedAt = DateTime.UtcNow,
            });

        db.Plans.Add(new Plan
        {
            PlanId = 1,
            Code = "free",
            Name = "Free",
            IsActive = true,
            MonthlyShareCodes = 2,
        });

        db.UserSubscriptions.Add(new UserSubscription
        {
            UserSubscriptionId = Guid.NewGuid(),
            UserId = studentId,
            PlanId = 1,
            Status = "active",
            StartedAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
        });

        await db.SaveChangesAsync();
    }

    private sealed class StubClassService : IClassService
    {
        public Task EnsureTeacherOwnsClassAsync(
            Guid teacherUserId,
            Guid classId,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task<bool> IsActiveClassMemberAsync(
            Guid userId,
            Guid classId,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(true);

        public Task<IReadOnlyList<CraftQuest.Application.Models.Teacher.TeacherClassSummaryDto>> ListTeacherClassesAsync(
            Guid teacherUserId,
            string? status = "active",
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task<CraftQuest.Application.Models.Teacher.TeacherClassSummaryDto> CreateAsync(
            Guid teacherUserId,
            CraftQuest.Application.Models.Teacher.CreateClassRequest request,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task UpdateAsync(
            Guid teacherUserId,
            Guid classId,
            CraftQuest.Application.Models.Teacher.UpdateClassRequest request,
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

        public Task<CraftQuest.Application.Models.Teacher.ClassDetailDto> GetDetailAsync(
            Guid teacherUserId,
            Guid classId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task AddMemberByEmailAsync(
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
    }

    private static ShareCodeService CreateService(
        CraftQuestDbContext db,
        IBillingService billing) =>
        new(
            db,
            billing,
            new StubClassService(),
            new StubNotificationService(),
            NullLogger<ShareCodeService>.Instance,
            Options.Create(new JoinLinkOptions
            {
                LinkBaseUrl = "https://api.craftquestai.com",
            }));

    private sealed class StubNotificationService : INotificationService
    {
        public Task NotifyAsync(
            Guid userId,
            string type,
            NotificationPayload payload,
            string? dedupKey = null,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task NotifyManyAsync(
            IReadOnlyList<Guid> userIds,
            string type,
            NotificationPayload payload,
            Func<Guid, string?>? dedupKeyFactory = null,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task EnqueueFanOutAsync(
            string eventType,
            string payloadJson,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task<NotificationListResultDto> ListAsync(
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
            RegisterDeviceTokenRequest request,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task RemoveDeviceTokenAsync(
            Guid userId,
            string token,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task<NotificationPreferencesDto> GetPreferencesAsync(
            Guid userId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task UpdatePreferencesAsync(
            Guid userId,
            UpdateNotificationPreferencesRequest request,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;
    }
}
