using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Auth;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Security;
using CraftQuest.Infrastructure.Services;
using CraftQuest.UnitTests.Billing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CraftQuest.UnitTests.Auth;

public class AuthServiceDeleteAccountTests
{
    [Fact]
    public async Task DeleteAccountAsync_SoftDeletesUser_AndRemovesDeviceTokens()
    {
        await using var db = CreateDb();
        await SeedStudentRoleAsync(db);
        var userId = await SeedActiveUserAsync(db, "delete@test.com", "TestPass123!");
        db.DeviceTokens.Add(new DeviceToken
        {
            DeviceTokenId = Guid.NewGuid(),
            UserId = userId,
            Token = "fcm-token-123",
            Platform = "android",
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        var service = CreateService(db);
        await service.DeleteAccountAsync(userId);

        var user = await db.Users.IgnoreQueryFilters().SingleAsync(u => u.UserId == userId);
        Assert.Equal(UserStatuses.Deleted, user.Status);
        Assert.NotNull(user.DeletedAt);
        Assert.Empty(await db.DeviceTokens.Where(t => t.UserId == userId).ToListAsync());
    }

    [Fact]
    public async Task DeleteAccountAsync_AlreadyDeleted_ThrowsNotFound()
    {
        await using var db = CreateDb();
        await SeedStudentRoleAsync(db);
        var userId = Guid.NewGuid();
        db.Users.Add(new User
        {
            UserId = userId,
            Email = "gone@test.com",
            PasswordHash = PasswordHasher.HashPassword("TestPass123!"),
            Status = "deleted",
            DeletedAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        var service = CreateService(db);
        var ex = await Assert.ThrowsAsync<AuthException>(() =>
            service.DeleteAccountAsync(userId));

        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task GetProfileAsync_DeletedUser_NotFound()
    {
        await using var db = CreateDb();
        await SeedStudentRoleAsync(db);
        var userId = await SeedActiveUserAsync(db, "active@test.com", "TestPass123!");
        var service = CreateService(db);
        await service.DeleteAccountAsync(userId);

        await Assert.ThrowsAsync<AuthException>(() => service.GetProfileAsync(userId));
    }

    private static AuthService CreateService(CraftQuestDbContext db)
    {
        var emailSender = new CapturingEmailSender();
        var billing = BillingTestHelpers.CreateService(db);
        var jwt = new JwtTokenService(Options.Create(new JwtOptions
        {
            SecretKey = "CraftQuest-UnitTest-Secret-Key-32chars!",
            Issuer = "test",
            Audience = "test",
        }));

        return new AuthService(
            db,
            jwt,
            billing,
            emailSender,
            new StubGoogleIdTokenValidator(),
            new StubAppleIdTokenValidator(),
            Options.Create(new PasswordResetOptions
            {
                Pepper = "test-pepper",
                TokenLifetimeMinutes = 60,
            }),
            Options.Create(new JoinLinkOptions
            {
                LinkBaseUrl = "https://api.craftquestai.com",
                WebAppUrl = "https://app.craftquestai.com",
            }),
            Options.Create(new ExternalAuthOptions()));
    }

    private static CraftQuestDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<CraftQuestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new CraftQuestDbContext(options);
    }

    private static async Task SeedStudentRoleAsync(CraftQuestDbContext db)
    {
        db.Roles.Add(new Role
        {
            Code = RoleCodes.Student,
            Name = "Student",
        });

        db.Plans.Add(new Plan
        {
            PlanId = 1,
            Code = "free",
            Name = "Free",
            IsActive = true,
            MonthlyAiCredits = 20,
            MaxQuizzes = 2,
            MaxQuestionsPerQuiz = 50,
        });

        await db.SaveChangesAsync();
    }

    private static async Task<Guid> SeedActiveUserAsync(
        CraftQuestDbContext db,
        string email,
        string password)
    {
        var userId = Guid.NewGuid();
        db.Users.Add(new User
        {
            UserId = userId,
            Email = email,
            PasswordHash = PasswordHasher.HashPassword(password),
            DisplayName = "Active User",
            Status = UserStatuses.Active,
            EmailVerifiedAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();
        return userId;
    }

    private sealed class StubGoogleIdTokenValidator : IGoogleIdTokenValidator
    {
        public Task<ExternalAuthUserInfo> ValidateAsync(string idToken, CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();
    }

    private sealed class StubAppleIdTokenValidator : IAppleIdTokenValidator
    {
        public Task<ExternalAuthUserInfo> ValidateAsync(string idToken, CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();
    }
}
