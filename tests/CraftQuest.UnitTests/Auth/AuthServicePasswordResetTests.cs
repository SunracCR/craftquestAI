using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Auth;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Security;
using CraftQuest.Infrastructure.Services;
using CraftQuest.UnitTests.Billing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CraftQuest.UnitTests.Auth;

public class AuthServicePasswordResetTests
{
    [Fact]
    public async Task RequestPasswordReset_UnknownEmail_DoesNotThrow()
    {
        await using var db = CreateDb();
        var service = CreateService(db);

        await service.RequestPasswordResetAsync(
            new ForgotPasswordRequest { Email = "missing@test.com" });

        Assert.Empty(await db.PasswordResetTokens.ToListAsync());
    }

    [Fact]
    public async Task ResetPassword_ValidToken_UpdatesHash()
    {
        await using var db = CreateDb();
        const string pepper = "test-pepper";
        var userId = await SeedUserAsync(db, "reset@test.com", "OldPass123!");
        var rawToken = Application.Services.PasswordResetTokenHasher.GenerateToken();
        var hash = Application.Services.PasswordResetTokenHasher.Hash(rawToken, pepper);

        db.PasswordResetTokens.Add(new PasswordResetToken
        {
            PasswordResetTokenId = Guid.NewGuid(),
            UserId = userId,
            TokenHash = hash,
            ExpiresAt = DateTime.UtcNow.AddHours(1),
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        var service = CreateService(db, pepper);
        await service.ResetPasswordAsync(new ResetPasswordRequest
        {
            Token = rawToken,
            NewPassword = "NewPass456!",
        });

        var user = await db.Users.SingleAsync(u => u.UserId == userId);
        Assert.True(PasswordHasher.VerifyPassword("NewPass456!", user.PasswordHash!));
    }

    [Fact]
    public async Task ResetPassword_ExpiredToken_Throws()
    {
        await using var db = CreateDb();
        const string pepper = "test-pepper";
        var userId = await SeedUserAsync(db, "expired@test.com", "OldPass123!");
        var rawToken = Application.Services.PasswordResetTokenHasher.GenerateToken();
        var hash = Application.Services.PasswordResetTokenHasher.Hash(rawToken, pepper);

        db.PasswordResetTokens.Add(new PasswordResetToken
        {
            PasswordResetTokenId = Guid.NewGuid(),
            UserId = userId,
            TokenHash = hash,
            ExpiresAt = DateTime.UtcNow.AddMinutes(-5),
            CreatedAt = DateTime.UtcNow.AddHours(-2),
        });
        await db.SaveChangesAsync();

        var service = CreateService(db, pepper);
        await Assert.ThrowsAsync<Application.Exceptions.AuthException>(() =>
            service.ResetPasswordAsync(new ResetPasswordRequest
            {
                Token = rawToken,
                NewPassword = "NewPass456!",
            }));
    }

    private static AuthService CreateService(CraftQuestDbContext db, string pepper = "test-pepper")
    {
        var billing = BillingTestHelpers.CreateService(db);
        var jwt = new JwtTokenService(Options.Create(new JwtOptions
        {
            SecretKey = "CraftQuest-UnitTest-Secret-Key-32chars!",
            Issuer = "test",
            Audience = "test",
        }));
        var email = new CapturingEmailSender();
        var resetOptions = Options.Create(new PasswordResetOptions
        {
            Pepper = pepper,
            TokenLifetimeMinutes = 60,
            AppResetUrlBase = "http://localhost/reset-password",
        });
        var joinLinkOptions = Options.Create(new JoinLinkOptions
        {
            LinkBaseUrl = "https://api.craftquestai.com",
            WebAppUrl = "https://app.craftquestai.com",
        });
        var externalAuthOptions = Options.Create(new ExternalAuthOptions());

        return new AuthService(
            db,
            jwt,
            billing,
            email,
            new StubGoogleIdTokenValidator(),
            new StubAppleIdTokenValidator(),
            resetOptions,
            joinLinkOptions,
            externalAuthOptions);
    }

    private static CraftQuestDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<CraftQuestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new CraftQuestDbContext(options);
    }

    private static async Task<Guid> SeedUserAsync(
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
            DisplayName = "Reset Test",
            Status = "active",
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
