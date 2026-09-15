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
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace CraftQuest.UnitTests.Auth;

public class AuthServiceDeleteAccountTests
{
    private const string TestPassword = "TestPass123!";
    private const string TestEmail = "delete@test.com";

    [Fact]
    public async Task DeleteAccountAsync_SoftDeletesUser_AndRemovesDeviceTokens()
    {
        await using var db = CreateDb();
        await SeedStudentRoleAsync(db);
        var userId = await SeedActiveUserAsync(db, TestEmail, TestPassword);
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
        Assert.Equal($"deleted+{userId:N}@deleted.invalid", user.Email);
        Assert.Null(user.PasswordHash);
        Assert.Null(user.DisplayName);
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
            PasswordHash = PasswordHasher.HashPassword(TestPassword),
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
        var userId = await SeedActiveUserAsync(db, "active@test.com", TestPassword);
        var service = CreateService(db);
        await service.DeleteAccountAsync(userId);

        await Assert.ThrowsAsync<AuthException>(() => service.GetProfileAsync(userId));
    }

    [Fact]
    public async Task LoginAsync_AfterDelete_ReturnsUnauthorized()
    {
        await using var db = CreateDb();
        await SeedStudentRoleAsync(db);
        var userId = await SeedActiveUserAsync(db, TestEmail, TestPassword);
        var service = CreateService(db);

        await service.DeleteAccountAsync(userId);

        var ex = await Assert.ThrowsAsync<AuthException>(() =>
            service.LoginAsync(new LoginRequest
            {
                Email = TestEmail,
                Password = TestPassword,
            }));

        Assert.Equal(401, ex.StatusCode);
    }

    [Fact]
    public async Task RegisterAsync_AfterDelete_AllowsSameEmailAgain()
    {
        await using var db = CreateDb();
        await SeedStudentRoleAsync(db);
        var userId = await SeedActiveUserAsync(db, TestEmail, TestPassword);
        var service = CreateService(db);

        await service.DeleteAccountAsync(userId);

        var result = await service.RegisterAsync(new RegisterRequest
        {
            Email = TestEmail,
            Password = "NewPass123!",
            DisplayName = "Fresh User",
        });

        Assert.True(result.RequiresEmailVerification);
        Assert.Equal(TestEmail, result.Email);

        var users = await db.Users
            .Where(u => u.EmailNormalized == TestEmail.ToUpperInvariant())
            .ToListAsync();
        Assert.Single(users);
        Assert.NotEqual(userId, users[0].UserId);
        Assert.Equal(UserStatuses.Pending, users[0].Status);
    }

    [Fact]
    public async Task LoginWithGoogleAsync_AfterDelete_CreatesNewUserWithSameSubject()
    {
        await using var db = CreateDb();
        await SeedStudentRoleAsync(db);
        const string googleSubject = "google-oauth-subject-123";
        const string googleEmail = "oauth@test.com";
        var oldUserId = await SeedActiveUserWithGoogleAsync(
            db,
            googleEmail,
            googleSubject);

        var googleValidator = new ConfigurableGoogleIdTokenValidator(
            new ExternalAuthUserInfo(googleSubject, googleEmail, "OAuth User", true));
        var service = CreateService(db, googleValidator);

        await service.DeleteAccountAsync(oldUserId);

        var auth = await service.LoginWithGoogleAsync(new ExternalLoginRequest
        {
            IdToken = "fake-token",
            Email = googleEmail,
            DisplayName = "OAuth User",
        });

        Assert.NotEqual(oldUserId, auth.User.UserId);
        Assert.Equal(googleEmail, auth.User.Email);

        var activeUsers = await db.Users
            .Where(u => u.EmailNormalized == googleEmail.ToUpperInvariant())
            .ToListAsync();
        Assert.Single(activeUsers);

        var provider = await db.AuthProviders.SingleAsync(
            ap => ap.ProviderCode == "google" && ap.ProviderSubject == googleSubject);
        Assert.Equal(activeUsers[0].UserId, provider.UserId);
    }

    [Fact]
    public async Task DeleteAccountAsync_AnonymizesAuthProviders()
    {
        await using var db = CreateDb();
        await SeedStudentRoleAsync(db);
        const string googleSubject = "google-subject-to-release";
        var userId = await SeedActiveUserWithGoogleAsync(
            db,
            "provider@test.com",
            googleSubject);
        var service = CreateService(db);

        await service.DeleteAccountAsync(userId);

        var provider = await db.AuthProviders.SingleAsync(ap => ap.UserId == userId);
        Assert.StartsWith($"deleted:{userId:N}:", provider.ProviderSubject);
        Assert.NotEqual(googleSubject, provider.ProviderSubject);
    }

    private static AuthService CreateService(
        CraftQuestDbContext db,
        IGoogleIdTokenValidator? googleValidator = null)
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
            googleValidator ?? new StubGoogleIdTokenValidator(),
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
            Options.Create(new ExternalAuthOptions()),
            Options.Create(new TurnstileOptions()),
            NullLogger<AuthService>.Instance);
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
            MaxQuestionsPerQuiz = 25,
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

    private static async Task<Guid> SeedActiveUserWithGoogleAsync(
        CraftQuestDbContext db,
        string email,
        string googleSubject)
    {
        var userId = Guid.NewGuid();
        var user = new User
        {
            UserId = userId,
            Email = email,
            DisplayName = "OAuth User",
            Status = UserStatuses.Active,
            EmailVerifiedAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
        };
        user.AuthProviders.Add(new AuthProvider
        {
            AuthProviderId = Guid.NewGuid(),
            UserId = userId,
            ProviderCode = "google",
            ProviderSubject = googleSubject,
            CreatedAt = DateTime.UtcNow,
        });
        db.Users.Add(user);
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

    private sealed class ConfigurableGoogleIdTokenValidator(ExternalAuthUserInfo identity)
        : IGoogleIdTokenValidator
    {
        public Task<ExternalAuthUserInfo> ValidateAsync(
            string idToken,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(identity);
    }
}
