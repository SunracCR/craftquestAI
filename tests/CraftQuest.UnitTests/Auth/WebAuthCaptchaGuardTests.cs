using System.Net;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Options;
using CraftQuest.Infrastructure.Security;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace CraftQuest.UnitTests.Auth;

public class WebAuthCaptchaGuardTests
{
    [Fact]
    public async Task EnsureValidAsync_DoesNotEnforce_WhenClientIsNotWeb()
    {
        var validator = new FakeCaptchaValidator { Result = false };
        var guard = CreateGuard(validator, enforce: true);

        await guard.EnsureValidAsync(
            clientPlatform: "android",
            remoteIp: "203.0.113.10",
            captchaToken: null);

        Assert.Equal(0, validator.CallCount);
    }

    [Fact]
    public async Task EnsureValidAsync_DoesNotEnforce_WhenKillSwitchDisabled()
    {
        var validator = new FakeCaptchaValidator { Result = false };
        var guard = CreateGuard(validator, enforce: false);

        await guard.EnsureValidAsync(
            clientPlatform: WebAuthCaptchaGuard.WebClientPlatformValue,
            remoteIp: "203.0.113.10",
            captchaToken: null);

        Assert.Equal(0, validator.CallCount);
    }

    [Fact]
    public async Task EnsureValidAsync_Throws_WhenWebClientMissingToken()
    {
        var validator = new FakeCaptchaValidator { Result = true };
        var guard = CreateGuard(validator, enforce: true);

        var ex = await Assert.ThrowsAsync<Application.Exceptions.AppException>(() =>
            guard.EnsureValidAsync(
                clientPlatform: WebAuthCaptchaGuard.WebClientPlatformValue,
                remoteIp: "203.0.113.10",
                captchaToken: null));

        Assert.Equal("CAPTCHA_INVALID", ex.ErrorCode);
        Assert.Equal(0, validator.CallCount);
    }

    [Fact]
    public async Task EnsureValidAsync_Throws_WhenWebClientTokenInvalid()
    {
        var validator = new FakeCaptchaValidator { Result = false };
        var guard = CreateGuard(validator, enforce: true);

        var ex = await Assert.ThrowsAsync<Application.Exceptions.AppException>(() =>
            guard.EnsureValidAsync(
                clientPlatform: WebAuthCaptchaGuard.WebClientPlatformValue,
                remoteIp: "203.0.113.10",
                captchaToken: "bad-token"));

        Assert.Equal("CAPTCHA_INVALID", ex.ErrorCode);
        Assert.Equal(1, validator.CallCount);
    }

    [Fact]
    public async Task EnsureValidAsync_Allows_WhenWebClientTokenValid()
    {
        var validator = new FakeCaptchaValidator { Result = true };
        var guard = CreateGuard(validator, enforce: true);

        await guard.EnsureValidAsync(
            clientPlatform: WebAuthCaptchaGuard.WebClientPlatformValue,
            remoteIp: "203.0.113.10",
            captchaToken: "good-token");

        Assert.Equal(1, validator.CallCount);
    }

    private static WebAuthCaptchaGuard CreateGuard(
        ICaptchaValidator validator,
        bool enforce) =>
        new(
            validator,
            Options.Create(new TurnstileOptions
            {
                SiteKey = "site-key",
                SecretKey = "secret-key",
                Enforce = enforce,
            }),
            NullLogger<WebAuthCaptchaGuard>.Instance);

    private sealed class FakeCaptchaValidator : ICaptchaValidator
    {
        public bool Result { get; set; }

        public int CallCount { get; private set; }

        public Task<bool> ValidateAsync(
            string? token,
            string? remoteIp,
            CancellationToken cancellationToken = default)
        {
            CallCount++;
            return Task.FromResult(Result);
        }
    }
}
