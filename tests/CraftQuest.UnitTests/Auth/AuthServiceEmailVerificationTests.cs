using CraftQuest.Application.Contracts;
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

public class AuthServiceEmailVerificationTests
{
    [Fact]
    public async Task RegisterAsync_CreatesPendingUser_AndSendsVerificationEmail()
    {
        await using var db = CreateDb();
        await SeedStudentRoleAsync(db);
        var emailSender = new CapturingEmailSender();
        var service = CreateService(db, emailSender);

        var result = await service.RegisterAsync(new RegisterRequest
        {
            Email = "pending@test.com",
            Password = "TestPass123!",
            DisplayName = "Pending User",
        });

        Assert.True(result.RequiresEmailVerification);
        Assert.Equal("pending@test.com", result.Email);

        var user = await db.Users.SingleAsync(u => u.Email == "pending@test.com");
        Assert.Equal("pending", user.Status);
        Assert.Null(user.EmailVerifiedAt);
        Assert.Single(await db.EmailVerificationTokens.Where(t => t.UserId == user.UserId).ToListAsync());
        Assert.NotNull(emailSender.LastPlainTextBody);
        Assert.Contains("verify-email/", emailSender.LastPlainTextBody, StringComparison.Ordinal);
    }

    [Fact]
    public async Task LoginAsync_PendingUser_ThrowsEmailNotVerified()
    {
        await using var db = CreateDb();
        await SeedStudentRoleAsync(db);
        var service = CreateService(db);

        await service.RegisterAsync(new RegisterRequest
        {
            Email = "blocked@test.com",
            Password = "TestPass123!",
        });

        var ex = await Assert.ThrowsAsync<Application.Exceptions.AuthException>(() =>
            service.LoginAsync(new LoginRequest
            {
                Email = "blocked@test.com",
                Password = "TestPass123!",
            }));

        Assert.Equal("EMAIL_NOT_VERIFIED", ex.ErrorCode);
    }

    [Fact]
    public async Task VerifyEmailAsync_ValidToken_ActivatesUserAndReturnsTokens()
    {
        await using var db = CreateDb();
        await SeedStudentRoleAsync(db);
        var emailSender = new CapturingEmailSender();
        var service = CreateService(db, emailSender);

        await service.RegisterAsync(new RegisterRequest
        {
            Email = "verify@test.com",
            Password = "TestPass123!",
        });

        var rawToken = emailSender.ExtractTokenFromLastEmail();
        Assert.False(string.IsNullOrWhiteSpace(rawToken));

        var auth = await service.VerifyEmailAsync(new VerifyEmailRequest { Token = rawToken! });

        Assert.False(string.IsNullOrWhiteSpace(auth.Tokens.AccessToken));

        var user = await db.Users.SingleAsync(u => u.Email == "verify@test.com");
        Assert.Equal("active", user.Status);
        Assert.NotNull(user.EmailVerifiedAt);
    }

    [Fact]
    public async Task ResendVerificationAsync_PendingUser_SendsAnotherEmail()
    {
        await using var db = CreateDb();
        await SeedStudentRoleAsync(db);
        var emailSender = new CapturingEmailSender();
        var service = CreateService(db, emailSender);

        await service.RegisterAsync(new RegisterRequest
        {
            Email = "resend@test.com",
            Password = "TestPass123!",
        });

        emailSender.Reset();

        await service.ResendVerificationAsync(new ResendVerificationRequest
        {
            Email = "resend@test.com",
        });

        Assert.NotNull(emailSender.LastPlainTextBody);
    }

    [Fact]
    public async Task ChangePasswordAsync_CreatesTokenWithoutApplyingPassword()
    {
        await using var db = CreateDb();
        var userId = await SeedActiveUserAsync(db, "change@test.com", "OldPass123!");
        var emailSender = new CapturingEmailSender();
        var service = CreateService(db, emailSender);

        var result = await service.ChangePasswordAsync(userId, new ChangePasswordRequest
        {
            CurrentPassword = "OldPass123!",
            NewPassword = "NewPass456!",
        });

        Assert.True(result.RequiresEmailConfirmation);

        var user = await db.Users.SingleAsync(u => u.UserId == userId);
        Assert.True(PasswordHasher.VerifyPassword("OldPass123!", user.PasswordHash!));
        Assert.Single(await db.PasswordChangeTokens.Where(t => t.UserId == userId).ToListAsync());
        Assert.Contains("confirm-password-change/", emailSender.LastPlainTextBody, StringComparison.Ordinal);
    }

    [Fact]
    public async Task ConfirmPasswordChangeAsync_AppliesNewPassword()
    {
        await using var db = CreateDb();
        var userId = await SeedActiveUserAsync(db, "confirm@test.com", "OldPass123!");
        var emailSender = new CapturingEmailSender();
        var service = CreateService(db, emailSender);

        await service.ChangePasswordAsync(userId, new ChangePasswordRequest
        {
            CurrentPassword = "OldPass123!",
            NewPassword = "NewPass456!",
        });

        var rawToken = emailSender.ExtractTokenFromLastEmail();
        Assert.False(string.IsNullOrWhiteSpace(rawToken));

        await service.ConfirmPasswordChangeAsync(new ConfirmPasswordChangeRequest
        {
            Token = rawToken!,
        });

        var user = await db.Users.SingleAsync(u => u.UserId == userId);
        Assert.True(PasswordHasher.VerifyPassword("NewPass456!", user.PasswordHash!));
    }

    private static AuthService CreateService(
        CraftQuestDbContext db,
        CapturingEmailSender? emailSender = null)
    {
        emailSender ??= new CapturingEmailSender();
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
            Status = "active",
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
