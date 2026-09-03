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
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace CraftQuest.UnitTests.Auth;

public class AuthServiceGuardianEmailTests
{
    [Fact]
    public async Task UpdateGuardianEmailAsync_PendingMinor_UpdatesEmailAndSendsConsent()
    {
        await using var db = CreateDb();
        await SeedStudentRoleAsync(db);
        var emailSender = new CapturingEmailSender();
        var service = CreateService(db, emailSender);

        await service.RegisterAsync(new RegisterRequest
        {
            Email = "minor@test.com",
            Password = "TestPass123!",
            DateOfBirth = DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-10)),
            GuardianEmail = "wrong@test.com",
        });

        emailSender.Reset();

        var result = await service.UpdateGuardianEmailAsync(new UpdateGuardianEmailRequest
        {
            Email = "minor@test.com",
            GuardianEmail = "guardian@test.com",
        });

        Assert.Equal("guardian@test.com", result.GuardianEmail);

        var user = await db.Users.SingleAsync(u => u.Email == "minor@test.com");
        Assert.Equal("guardian@test.com", user.GuardianEmail);
        Assert.NotNull(emailSender.LastPlainTextBody);
        Assert.Contains("parental-consent/", emailSender.LastPlainTextBody, StringComparison.Ordinal);
    }

    [Fact]
    public async Task ResendParentalConsentAsync_BeforeEmailVerified_StillSendsConsentEmail()
    {
        await using var db = CreateDb();
        await SeedStudentRoleAsync(db);
        var emailSender = new CapturingEmailSender();
        var service = CreateService(db, emailSender);

        await service.RegisterAsync(new RegisterRequest
        {
            Email = "minor2@test.com",
            Password = "TestPass123!",
            DateOfBirth = DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-10)),
            GuardianEmail = "guardian@test.com",
        });

        emailSender.Reset();

        await service.ResendParentalConsentAsync(new ResendParentalConsentRequest
        {
            Email = "minor2@test.com",
        });

        Assert.NotNull(emailSender.LastPlainTextBody);
        Assert.Contains("parental-consent/", emailSender.LastPlainTextBody, StringComparison.Ordinal);
    }

    [Fact]
    public async Task UpdateGuardianEmailAsync_ActiveUser_ThrowsUnavailable()
    {
        await using var db = CreateDb();
        await SeedStudentRoleAsync(db);
        var service = CreateService(db);

        await service.RegisterAsync(new RegisterRequest
        {
            Email = "active@test.com",
            Password = "TestPass123!",
        });

        var ex = await Assert.ThrowsAsync<Application.Exceptions.AuthException>(() =>
            service.UpdateGuardianEmailAsync(new UpdateGuardianEmailRequest
            {
                Email = "active@test.com",
                GuardianEmail = "guardian@test.com",
            }));

        Assert.Equal("GUARDIAN_EMAIL_UPDATE_UNAVAILABLE", ex.ErrorCode);
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
