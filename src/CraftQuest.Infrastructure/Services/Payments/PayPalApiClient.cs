using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Payments;

public class PayPalApiClient(
    HttpClient httpClient,
    IOptions<PaymentOptions> options,
    ILogger<PayPalApiClient> logger)
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

        var body = await SendAuthenticatedAsync(
            () =>
            {
                var request = new HttpRequestMessage(HttpMethod.Post, "/v2/checkout/orders");
                request.Content = JsonContent.Create(payload, options: JsonOptions);
                return request;
            },
            cancellationToken);
        try
        {
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
        catch (JsonException ex)
        {
            throw WrapPayPalResponseParseFailure(ex);
        }
    }

    public async Task<(string SubscriptionId, string? ApprovalUrl)> CreateSubscriptionAsync(
        string payPalPlanId,
        string customId,
        CancellationToken cancellationToken)
    {
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

        var body = await SendAuthenticatedAsync(
            () =>
            {
                var request = new HttpRequestMessage(HttpMethod.Post, "/v1/billing/subscriptions");
                request.Content = JsonContent.Create(payload, options: JsonOptions);
                return request;
            },
            cancellationToken);
        try
        {
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
        catch (JsonException ex)
        {
            throw WrapPayPalResponseParseFailure(ex);
        }
    }

    public async Task<PayPalSubscriptionDetails> GetSubscriptionAsync(
        string subscriptionId,
        CancellationToken cancellationToken)
    {
        var body = await SendAuthenticatedAsync(
            () => new HttpRequestMessage(
                HttpMethod.Get,
                $"/v1/billing/subscriptions/{subscriptionId}"),
            cancellationToken);
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
        await SuspendSubscriptionAsync(subscriptionId, reason, cancellationToken);
    }

    public async Task SuspendSubscriptionAsync(
        string subscriptionId,
        string reason,
        CancellationToken cancellationToken)
    {
        await SendAuthenticatedAsync(
            () =>
            {
                var request = new HttpRequestMessage(
                    HttpMethod.Post,
                    $"/v1/billing/subscriptions/{subscriptionId}/suspend");
                request.Content = JsonContent.Create(
                    new { reason },
                    options: JsonOptions);
                return request;
            },
            cancellationToken);
    }

    public async Task ActivateSubscriptionAsync(
        string subscriptionId,
        string reason,
        CancellationToken cancellationToken)
    {
        await SendAuthenticatedAsync(
            () =>
            {
                var request = new HttpRequestMessage(
                    HttpMethod.Post,
                    $"/v1/billing/subscriptions/{subscriptionId}/activate");
                request.Content = JsonContent.Create(
                    new { reason },
                    options: JsonOptions);
                return request;
            },
            cancellationToken);
    }

    public async Task<bool> VerifyWebhookSignatureAsync(
        IReadOnlyDictionary<string, string> headers,
        string body,
        CancellationToken cancellationToken)
    {
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

        try
        {
            var responseBody = await SendAuthenticatedAsync(
                () =>
                {
                    var request = new HttpRequestMessage(
                        HttpMethod.Post,
                        "/v1/notifications/verify-webhook-signature");
                    request.Content = JsonContent.Create(payload, options: JsonOptions);
                    return request;
                },
                cancellationToken);
            using var doc = JsonDocument.Parse(responseBody);
            return doc.RootElement.TryGetProperty("verification_status", out var statusEl)
                && statusEl.GetString()?.Equals("SUCCESS", StringComparison.OrdinalIgnoreCase) == true;
        }
        catch (AppException ex) when (ex.StatusCode == 502)
        {
            logger.LogWarning(ex, "PayPal webhook signature verification failed.");
            return false;
        }
    }

    public async Task CaptureOrderAsync(string orderId, CancellationToken cancellationToken)
    {
        try
        {
            await SendAuthenticatedAsync(
                () =>
                {
                    var captureRequest = new HttpRequestMessage(
                        HttpMethod.Post,
                        $"/v2/checkout/orders/{orderId}/capture");
                    captureRequest.Content = JsonContent.Create(new { }, options: JsonOptions);
                    return captureRequest;
                },
                cancellationToken);
        }
        catch (AppException ex) when (ex.StatusCode == 502 && IsPayPalOrderAlreadyCaptured(ex.Message))
        {
            logger.LogInformation("PayPal order {OrderId} was already captured.", orderId);
        }
    }

    private static bool IsPayPalOrderAlreadyCaptured(string body) =>
        body.Contains("ORDER_ALREADY_CAPTURED", StringComparison.OrdinalIgnoreCase);

    private string? _accessToken;
    private DateTime _accessTokenExpiresAt = DateTime.MinValue;

    private async Task<string> SendAuthenticatedAsync(
        Func<HttpRequestMessage> requestFactory,
        CancellationToken cancellationToken)
    {
        for (var attempt = 0; attempt < 2; attempt++)
        {
            await EnsureAccessTokenAsync(cancellationToken);
            using var request = requestFactory();
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _accessToken);

            string body;
            HttpResponseMessage response;
            try
            {
                response = await httpClient.SendAsync(request, cancellationToken);
                body = await response.Content.ReadAsStringAsync(cancellationToken);
            }
            catch (Exception ex) when (IsPayPalTransportFailure(ex))
            {
                throw WrapPayPalTransportFailure(ex);
            }

            if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized && attempt == 0)
            {
                InvalidateAccessToken();
                continue;
            }

            if (!response.IsSuccessStatusCode)
            {
                throw new AppException(
                    $"PayPal API call failed ({(int)response.StatusCode}): {body}",
                    response.StatusCode is System.Net.HttpStatusCode.TooManyRequests
                        or >= System.Net.HttpStatusCode.InternalServerError
                        ? 503
                        : 502);
            }

            return body;
        }

        throw new AppException("PayPal authentication failed after retry.", 502);
    }

    private void InvalidateAccessToken()
    {
        _accessToken = null;
        _accessTokenExpiresAt = DateTime.MinValue;
    }

    private async Task EnsureAccessTokenAsync(CancellationToken cancellationToken)
    {
        if (!string.IsNullOrEmpty(_accessToken)
            && DateTime.UtcNow < _accessTokenExpiresAt.AddMinutes(-1))
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

        string body;
        HttpResponseMessage response;
        try
        {
            response = await httpClient.SendAsync(request, cancellationToken);
            body = await response.Content.ReadAsStringAsync(cancellationToken);
        }
        catch (Exception ex) when (IsPayPalTransportFailure(ex))
        {
            throw WrapPayPalTransportFailure(ex);
        }

        if (!response.IsSuccessStatusCode)
        {
            throw new AppException($"PayPal auth failed: {body}", 502);
        }

        try
        {
            using var doc = JsonDocument.Parse(body);
            _accessToken = doc.RootElement.GetProperty("access_token").GetString();
            var expiresIn = doc.RootElement.TryGetProperty("expires_in", out var expiresEl)
                ? expiresEl.GetInt32()
                : 3600;
            _accessTokenExpiresAt = DateTime.UtcNow.AddSeconds(Math.Max(60, expiresIn));
        }
        catch (JsonException ex)
        {
            throw WrapPayPalResponseParseFailure(ex);
        }
    }

    private static bool IsPayPalTransportFailure(Exception ex) =>
        ex is HttpRequestException or TaskCanceledException or JsonException;

    private AppException WrapPayPalTransportFailure(Exception ex)
    {
        logger.LogWarning(ex, "PayPal transport failure.");
        return new AppException(
            "Unable to connect to PayPal. Please try again later.",
            503);
    }

    private static AppException WrapPayPalResponseParseFailure(JsonException ex) =>
        new(
            "PayPal returned an unexpected response. Please try again later.",
            502);
}

public sealed record PayPalSubscriptionDetails(
    string Status,
    string? PlanId,
    string? CustomId,
    DateTime? NextBillingTime);
