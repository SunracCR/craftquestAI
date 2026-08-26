using System.Net;
using CraftQuest.Application.Options;
using CraftQuest.Infrastructure.Security;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace CraftQuest.UnitTests.Auth;

public class TurnstileCaptchaValidatorTests
{
    [Fact]
    public async Task ValidateAsync_ReturnsFalse_WhenTokenMissing()
    {
        var validator = CreateValidator(new StubHttpMessageHandler(_ => new HttpResponseMessage(HttpStatusCode.OK)));

        var result = await validator.ValidateAsync(null, "127.0.0.1");

        Assert.False(result);
    }

    [Fact]
    public async Task ValidateAsync_ReturnsTrue_WhenSiteverifySucceeds()
    {
        var handler = new StubHttpMessageHandler(_ => new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent("""{"success":true}"""),
        });
        var validator = CreateValidator(handler);

        var result = await validator.ValidateAsync("token-123", "127.0.0.1");

        Assert.True(result);
        Assert.Equal("secret-key", handler.LastFormBody?["secret"]);
        Assert.Equal("token-123", handler.LastFormBody?["response"]);
    }

    [Fact]
    public async Task ValidateAsync_ReturnsFalse_WhenSiteverifyFails()
    {
        var handler = new StubHttpMessageHandler(_ => new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent("""{"success":false,"error-codes":["invalid-input-response"]}"""),
        });
        var validator = CreateValidator(handler);

        var result = await validator.ValidateAsync("token-123", "127.0.0.1");

        Assert.False(result);
    }

    private static TurnstileCaptchaValidator CreateValidator(HttpMessageHandler handler)
    {
        var httpClient = new HttpClient(handler);
        return new TurnstileCaptchaValidator(
            httpClient,
            Options.Create(new TurnstileOptions
            {
                SiteKey = "site-key",
                SecretKey = "secret-key",
            }),
            NullLogger<TurnstileCaptchaValidator>.Instance);
    }

    private sealed class StubHttpMessageHandler(
        Func<HttpRequestMessage, HttpResponseMessage> responder) : HttpMessageHandler
    {
        public Dictionary<string, string>? LastFormBody { get; private set; }

        protected override async Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            if (request.Content is FormUrlEncodedContent formContent)
            {
                var raw = await formContent.ReadAsStringAsync(cancellationToken);
                LastFormBody = raw
                    .Split('&', StringSplitOptions.RemoveEmptyEntries)
                    .Select(part => part.Split('=', 2))
                    .ToDictionary(
                        parts => Uri.UnescapeDataString(parts[0]),
                        parts => parts.Length > 1 ? Uri.UnescapeDataString(parts[1]) : string.Empty);
            }

            return responder(request);
        }
    }
}
