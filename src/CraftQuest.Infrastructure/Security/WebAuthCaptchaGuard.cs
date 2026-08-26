using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Security;

public sealed class WebAuthCaptchaGuard(
    ICaptchaValidator captchaValidator,
    IOptions<TurnstileOptions> options,
    ILogger<WebAuthCaptchaGuard> logger) : IWebAuthCaptchaGuard
{
    public const string ClientPlatformHeaderName = "X-Client-Platform";
    public const string WebClientPlatformValue = "web";

    private readonly TurnstileOptions _options = options.Value;

    public async Task EnsureValidAsync(
        string? clientPlatform,
        string? remoteIp,
        string? captchaToken,
        CancellationToken cancellationToken = default)
    {
        if (!ShouldEnforce(clientPlatform))
        {
            if (!string.IsNullOrWhiteSpace(captchaToken))
            {
                var valid = await captchaValidator.ValidateAsync(
                    captchaToken,
                    remoteIp,
                    cancellationToken);
                if (!valid)
                {
                    logger.LogInformation(
                        "Optional Turnstile token from web client failed validation.");
                }
            }

            return;
        }

        if (string.IsNullOrWhiteSpace(captchaToken))
        {
            throw new AppException(
                "Captcha verification failed.",
                400,
                "CAPTCHA_INVALID");
        }

        var isValid = await captchaValidator.ValidateAsync(
            captchaToken,
            remoteIp,
            cancellationToken);

        if (!isValid)
        {
            throw new AppException(
                "Captcha verification failed.",
                400,
                "CAPTCHA_INVALID");
        }
    }

    internal bool ShouldEnforce(string? clientPlatform)
    {
        if (!_options.Enforce)
        {
            return false;
        }

        return string.Equals(
            clientPlatform,
            WebClientPlatformValue,
            StringComparison.OrdinalIgnoreCase);
    }
}
