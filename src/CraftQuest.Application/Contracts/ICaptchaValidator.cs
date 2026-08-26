namespace CraftQuest.Application.Contracts;

public interface ICaptchaValidator
{
    Task<bool> ValidateAsync(
        string? token,
        string? remoteIp,
        CancellationToken cancellationToken = default);
}
