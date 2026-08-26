namespace CraftQuest.Application.Contracts;

public interface IWebAuthCaptchaGuard
{
    Task EnsureValidAsync(
        string? clientPlatform,
        string? remoteIp,
        string? captchaToken,
        CancellationToken cancellationToken = default);
}
