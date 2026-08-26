using System.Net.Http.Json;
using System.Text.Json.Serialization;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Security;

public sealed class TurnstileCaptchaValidator(
    HttpClient httpClient,
    IOptions<TurnstileOptions> options,
    ILogger<TurnstileCaptchaValidator> logger) : ICaptchaValidator
{
    private readonly TurnstileOptions _options = options.Value;

    public async Task<bool> ValidateAsync(
        string? token,
        string? remoteIp,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            return false;
        }

        if (string.IsNullOrWhiteSpace(_options.SecretKey))
        {
            logger.LogWarning("Turnstile secret key is not configured; rejecting captcha token.");
            return false;
        }

        try
        {
            using var content = new FormUrlEncodedContent(new Dictionary<string, string>
            {
                ["secret"] = _options.SecretKey,
                ["response"] = token,
                ["remoteip"] = remoteIp ?? string.Empty,
            });

            using var response = await httpClient.PostAsync(
                "https://challenges.cloudflare.com/turnstile/v0/siteverify",
                content,
                cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning(
                    "Turnstile siteverify returned HTTP {StatusCode}.",
                    (int)response.StatusCode);
                return false;
            }

            var payload = await response.Content.ReadFromJsonAsync<TurnstileVerifyResponse>(
                cancellationToken: cancellationToken);

            if (payload?.Success != true)
            {
                logger.LogInformation(
                    "Turnstile verification failed. ErrorCodes={ErrorCodes}",
                    payload?.ErrorCodes is { Count: > 0 } codes
                        ? string.Join(',', codes)
                        : "(none)");
            }

            return payload?.Success == true;
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
        {
            logger.LogWarning(ex, "Turnstile siteverify request failed.");
            return false;
        }
    }

    private sealed class TurnstileVerifyResponse
    {
        [JsonPropertyName("success")]
        public bool Success { get; init; }

        [JsonPropertyName("error-codes")]
        public List<string>? ErrorCodes { get; init; }
    }
}
