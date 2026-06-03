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

    public async Task<(string SubscriptionId, string? ApprovalUrl)> CreateSubscriptionAsync(
        string payPalPlanId,
        string customId,
        CancellationToken cancellationToken)
    {
        await EnsureAccessTokenAsync(cancellationToken);
        var paypal = options.Value.PayPal;

        var payload = new
        {
            plan_id = payPalPlanId,
            custom_id = customId,
            application_context = new
            {
                return_url = paypal.ReturnUrl,
                cancel_url = paypal.CancelUrl,
                user_action = "SUBSCRIBE_NOW",
            },
        };

        using var request = new HttpRequestMessage(HttpMethod.Post, "/v1/billing/subscriptions");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _accessToken);
        request.Content = JsonContent.Create(payload, options: JsonOptions);

        var response = await httpClient.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new AppException($"PayPal create subscription failed: {body}", 502);
        }

        using var doc = JsonDocument.Parse(body);
        var subscriptionId = doc.RootElement.GetProperty("id").GetString()
            ?? throw new AppException("PayPal subscription id missing.", 502);

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

        return (subscriptionId, approvalUrl);
    }

    public async Task<PayPalSubscriptionDetails> GetSubscriptionAsync(
        string subscriptionId,
        CancellationToken cancellationToken)
    {
        await EnsureAccessTokenAsync(cancellationToken);

        using var request = new HttpRequestMessage(
            HttpMethod.Get,
            $"/v1/billing/subscriptions/{subscriptionId}");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _accessToken);

        var response = await httpClient.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new AppException($"PayPal get subscription failed: {body}", 502);
        }

        using var doc = JsonDocument.Parse(body);
        var root = doc.RootElement;
        var status = root.GetProperty("status").GetString() ?? "UNKNOWN";
        var planId = root.TryGetProperty("plan_id", out var planEl)
            ? planEl.GetString()
            : null;
        var customId = root.TryGetProperty("custom_id", out var customEl)
            ? customEl.GetString()
            : null;

        DateTime? nextBilling = null;
        if (root.TryGetProperty("billing_info", out var billingInfo)
            && billingInfo.TryGetProperty("next_billing_time", out var nextBillingEl))
        {
            var raw = nextBillingEl.GetString();
            if (!string.IsNullOrWhiteSpace(raw)
                && DateTime.TryParse(raw, null, System.Globalization.DateTimeStyles.RoundtripKind, out var parsed))
            {
                nextBilling = parsed.ToUniversalTime();
            }
        }

        return new PayPalSubscriptionDetails(status, planId, customId, nextBilling);
    }

    public async Task CancelSubscriptionAtPeriodEndAsync(
        string subscriptionId,
        string reason,
        CancellationToken cancellationToken)
    {
        await EnsureAccessTokenAsync(cancellationToken);

        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            $"/v1/billing/subscriptions/{subscriptionId}/cancel");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _accessToken);
        request.Content = JsonContent.Create(
            new { reason },
            options: JsonOptions);

        var response = await httpClient.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new AppException($"PayPal cancel subscription failed: {body}", 502);
        }
    }

    public async Task ActivateSubscriptionAsync(
        string subscriptionId,
        string reason,
        CancellationToken cancellationToken)
    {
        await EnsureAccessTokenAsync(cancellationToken);

        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            $"/v1/billing/subscriptions/{subscriptionId}/activate");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _accessToken);
        request.Content = JsonContent.Create(
            new { reason },
            options: JsonOptions);

        var response = await httpClient.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new AppException($"PayPal activate subscription failed: {body}", 502);
        }
    }

    public async Task<bool> VerifyWebhookSignatureAsync(
        IReadOnlyDictionary<string, string> headers,
        string body,
        CancellationToken cancellationToken)
    {
        await EnsureAccessTokenAsync(cancellationToken);

        static string GetHeader(IReadOnlyDictionary<string, string> map, string name) =>
            map.TryGetValue(name, out var value) ? value : string.Empty;

        using var webhookEvent = JsonDocument.Parse(body);
        var payload = new
        {
            auth_algo = GetHeader(headers, "PAYPAL-AUTH-ALGO"),
            cert_url = GetHeader(headers, "PAYPAL-CERT-URL"),
            transmission_id = GetHeader(headers, "PAYPAL-TRANSMISSION-ID"),
            transmission_sig = GetHeader(headers, "PAYPAL-TRANSMISSION-SIG"),
            transmission_time = GetHeader(headers, "PAYPAL-TRANSMISSION-TIME"),
            webhook_id = options.Value.PayPal.WebhookId,
            webhook_event = webhookEvent.RootElement,
        };

        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            "/v1/notifications/verify-webhook-signature");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _accessToken);
        request.Content = JsonContent.Create(payload, options: JsonOptions);

        var response = await httpClient.SendAsync(request, cancellationToken);
        var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            return false;
        }

        using var doc = JsonDocument.Parse(responseBody);
        return doc.RootElement.TryGetProperty("verification_status", out var statusEl)
            && statusEl.GetString()?.Equals("SUCCESS", StringComparison.OrdinalIgnoreCase) == true;
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

public sealed record PayPalSubscriptionDetails(
    string Status,
    string? PlanId,
    string? CustomId,
    DateTime? NextBillingTime);
