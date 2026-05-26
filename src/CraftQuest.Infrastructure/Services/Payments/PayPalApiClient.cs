using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Options;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Payments;

public class PayPalApiClient(
    HttpClient httpClient,
    IOptions<PaymentOptions> options)
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public async Task<(string OrderId, string? ApprovalUrl)> CreateOrderAsync(
        decimal amount,
        string currencyCode,
        string description,
        CancellationToken cancellationToken)
    {
        await EnsureAccessTokenAsync(cancellationToken);
        var paypal = options.Value.PayPal;

        var payload = new
        {
            intent = "CAPTURE",
            purchase_units = new[]
            {
                new
                {
                    description,
                    amount = new
                    {
                        currency_code = currencyCode,
                        value = amount.ToString("F2", System.Globalization.CultureInfo.InvariantCulture),
                    },
                },
            },
            application_context = new
            {
                return_url = paypal.ReturnUrl,
                cancel_url = paypal.CancelUrl,
                user_action = "PAY_NOW",
            },
        };

        using var request = new HttpRequestMessage(HttpMethod.Post, "/v2/checkout/orders");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _accessToken);
        request.Content = JsonContent.Create(payload, options: JsonOptions);

        var response = await httpClient.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new AppException($"PayPal create order failed: {body}", 502);
        }

        using var doc = JsonDocument.Parse(body);
        var orderId = doc.RootElement.GetProperty("id").GetString()
            ?? throw new AppException("PayPal order id missing.", 502);

        string? approvalUrl = null;
        if (doc.RootElement.TryGetProperty("links", out var links))
        {
            foreach (var link in links.EnumerateArray())
            {
                if (link.GetProperty("rel").GetString() == "approve")
                {
                    approvalUrl = link.GetProperty("href").GetString();
                    break;
                }
            }
        }

        return (orderId, approvalUrl);
    }

    public async Task CaptureOrderAsync(string orderId, CancellationToken cancellationToken)
    {
        await EnsureAccessTokenAsync(cancellationToken);

        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            $"/v2/checkout/orders/{orderId}/capture");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _accessToken);
        request.Content = JsonContent.Create(new { }, options: JsonOptions);

        var response = await httpClient.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new AppException($"PayPal capture failed: {body}", 502);
        }
    }

    private string? _accessToken;

    private async Task EnsureAccessTokenAsync(CancellationToken cancellationToken)
    {
        if (!string.IsNullOrEmpty(_accessToken))
        {
            return;
        }

        var paypal = options.Value.PayPal;
        if (string.IsNullOrWhiteSpace(paypal.ClientId) ||
            string.IsNullOrWhiteSpace(paypal.ClientSecret))
        {
            throw new AppException("PayPal credentials are not configured.", 503);
        }

        using var request = new HttpRequestMessage(HttpMethod.Post, "/v1/oauth2/token");
        request.Headers.Authorization = new AuthenticationHeaderValue(
            "Basic",
            Convert.ToBase64String(
                System.Text.Encoding.UTF8.GetBytes($"{paypal.ClientId}:{paypal.ClientSecret}")));

        request.Content = new FormUrlEncodedContent(
            new Dictionary<string, string> { ["grant_type"] = "client_credentials" });

        var response = await httpClient.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new AppException($"PayPal auth failed: {body}", 502);
        }

        using var doc = JsonDocument.Parse(body);
        _accessToken = doc.RootElement.GetProperty("access_token").GetString();
    }
}
