using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace CraftQuest.IntegrationTests;

public class ApiSmokeTests : IClassFixture<CraftQuestWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly CraftQuestWebApplicationFactory _factory;

    public ApiSmokeTests(CraftQuestWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Health_ReturnsSuccess()
    {
        var response = await _client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task ForgotPassword_ReturnsNoContent()
    {
        var response = await _client.PostAsJsonAsync(
            "/api/auth/forgot-password",
            new { email = "nobody@craftquest.test" });

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    [Fact]
    public async Task Auth_Google_ReturnsNotImplemented()
    {
        var response = await _client.PostAsync("/api/auth/google", null);

        Assert.Equal(HttpStatusCode.NotImplemented, response.StatusCode);

        var body = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(body);
        Assert.True(doc.RootElement.TryGetProperty("message", out var message));
        Assert.Contains("Google", message.GetString(), StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Auth_Refresh_ReturnsNewTokens_AndMeAcceptsNewAccessToken()
    {
        var email = $"refresh-{Guid.NewGuid():N}@craftquest.test";
        var authBody = await RegisterAndVerifyAsync(email, "TestPass123!", "Refresh Test");
        var initialRefresh = authBody.GetProperty("tokens").GetProperty("refreshToken").GetString();
        Assert.False(string.IsNullOrWhiteSpace(initialRefresh));

        var refreshResponse = await _client.PostAsJsonAsync(
            "/api/auth/refresh",
            new { refreshToken = initialRefresh });

        Assert.Equal(HttpStatusCode.OK, refreshResponse.StatusCode);

        var refreshBody = await refreshResponse.Content.ReadFromJsonAsync<JsonElement>();
        var newAccess = refreshBody.GetProperty("accessToken").GetString();
        var newRefresh = refreshBody.GetProperty("refreshToken").GetString();
        Assert.False(string.IsNullOrWhiteSpace(newAccess));
        Assert.False(string.IsNullOrWhiteSpace(newRefresh));
        Assert.NotEqual(initialRefresh, newRefresh);

        var meRequest = new HttpRequestMessage(HttpMethod.Get, "/api/auth/me");
        meRequest.Headers.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", newAccess);
        var meResponse = await _client.SendAsync(meRequest);

        Assert.Equal(HttpStatusCode.OK, meResponse.StatusCode);
    }

    private async Task<JsonElement> RegisterAndVerifyAsync(
        string email,
        string password,
        string displayName)
    {
        _factory.EmailSender.Reset();

        var registerResponse = await _client.PostAsJsonAsync(
            "/api/auth/register",
            new { email, password, displayName });

        Assert.Equal(HttpStatusCode.Created, registerResponse.StatusCode);

        var registerBody = await registerResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(registerBody.GetProperty("requiresEmailVerification").GetBoolean());

        var token = _factory.EmailSender.ExtractTokenFromLastEmail();
        Assert.False(string.IsNullOrWhiteSpace(token));

        var verifyResponse = await _client.PostAsJsonAsync(
            "/api/auth/verify-email",
            new { token });

        Assert.Equal(HttpStatusCode.OK, verifyResponse.StatusCode);
        return (await verifyResponse.Content.ReadFromJsonAsync<JsonElement>())!;
    }
}
