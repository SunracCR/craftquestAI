using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Options;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Payments;

public sealed class AppleAppStoreSubscriptionVerifier(
    IHttpClientFactory httpClientFactory,
    IOptions<PaymentOptions> options)
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    public async Task<MobileStoreSubscriptionDetails> VerifyAsync(
        string productId,
        string purchaseToken,
        string? transactionId,
        CancellationToken cancellationToken)
    {
        var mobile = options.Value.Mobile;
        var resolver = new StoreProductResolver(options.Value);
        var (planCode, billingCycle) = resolver.Resolve(productId);

        if (!string.IsNullOrWhiteSpace(transactionId)
            && !string.IsNullOrWhiteSpace(mobile.AppleIssuerId)
            && !string.IsNullOrWhiteSpace(mobile.AppleKeyId)
            && !string.IsNullOrWhiteSpace(mobile.ApplePrivateKeyPath)
            && File.Exists(mobile.ApplePrivateKeyPath))
        {
            return await VerifyViaAppStoreServerApiAsync(
                productId,
                planCode,
                billingCycle,
                transactionId,
                mobile,
                cancellationToken);
        }

        if (!string.IsNullOrWhiteSpace(mobile.AppleSharedSecret))
        {
            return await VerifyViaReceiptAsync(
                purchaseToken,
                productId,
                planCode,
                billingCycle,
                mobile,
                cancellationToken);
        }

        throw new AppException(
            "App Store is not configured. Set Apple Issuer/Key/PrivateKey or AppleSharedSecret.",
            503);
    }

    private async Task<MobileStoreSubscriptionDetails> VerifyViaAppStoreServerApiAsync(
        string productId,
        string planCode,
        string billingCycle,
        string transactionId,
        MobileStoreOptions mobile,
        CancellationToken cancellationToken)
    {
        var pem = await File.ReadAllTextAsync(mobile.ApplePrivateKeyPath, cancellationToken);
        var jwt = AppleAppStoreJwtFactory.CreateToken(
            mobile.AppleIssuerId,
            mobile.AppleKeyId,
            mobile.AppleBundleId,
            pem);

        var baseUrl = mobile.AppleEnvironment.Equals("Production", StringComparison.OrdinalIgnoreCase)
            ? "https://api.storekit.itunes.apple.com"
            : "https://api.storekit-sandbox.itunes.apple.com";

        var client = httpClientFactory.CreateClient(nameof(AppleAppStoreSubscriptionVerifier));
        using var request = new HttpRequestMessage(
            HttpMethod.Get,
            $"{baseUrl}/inApps/v1/transactions/{transactionId}");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", jwt);

        var response = await client.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new AppException($"App Store transaction lookup failed: {body}", 502);
        }

        using var doc = JsonDocument.Parse(body);
        if (!doc.RootElement.TryGetProperty("signedTransactionInfo", out var signedInfoEl))
        {
            throw new AppException("App Store response missing signedTransactionInfo.", 502);
        }

        var payload = DecodeAppleJwsPayload(signedInfoEl.GetString()!);
        var expiresMs = ReadLong(payload, "expiresDate");
        var originalTransactionId = ReadString(payload, "originalTransactionId") ?? transactionId;
        var storeProductId = ReadString(payload, "productId") ?? productId;
        var (_, resolvedCycle) = new StoreProductResolver(options.Value).Resolve(storeProductId);

        var periodEnd = expiresMs > 0
            ? DateTimeOffset.FromUnixTimeMilliseconds(expiresMs).UtcDateTime
            : (DateTime?)null;

        var isActive = periodEnd is null || periodEnd > DateTime.UtcNow;

        return new MobileStoreSubscriptionDetails
        {
            PlanCode = planCode,
            BillingCycle = resolvedCycle,
            ProviderSubscriptionId = originalTransactionId,
            IsActive = isActive,
            AutoRenewEnabled = true,
            PeriodEnd = periodEnd,
            LatestTransactionId = transactionId,
        };
    }

    private async Task<MobileStoreSubscriptionDetails> VerifyViaReceiptAsync(
        string receiptData,
        string productId,
        string planCode,
        string billingCycle,
        MobileStoreOptions mobile,
        CancellationToken cancellationToken)
    {
        var verifyUrl = mobile.AppleEnvironment.Equals("Production", StringComparison.OrdinalIgnoreCase)
            ? "https://buy.itunes.apple.com/verifyReceipt"
            : "https://sandbox.itunes.apple.com/verifyReceipt";

        var client = httpClientFactory.CreateClient(nameof(AppleAppStoreSubscriptionVerifier));
        var payload = JsonSerializer.Serialize(new Dictionary<string, object>
        {
            ["receipt-data"] = receiptData,
            ["password"] = mobile.AppleSharedSecret,
            ["exclude-old-transactions"] = true,
        });

        using var request = new HttpRequestMessage(HttpMethod.Post, verifyUrl)
        {
            Content = new StringContent(payload, Encoding.UTF8, "application/json"),
        };

        var response = await client.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new AppException($"Apple verifyReceipt failed: {body}", 502);
        }

        using var doc = JsonDocument.Parse(body);
        var status = doc.RootElement.GetProperty("status").GetInt32();
        if (status != 0)
        {
            throw new AppException($"Apple verifyReceipt status {status}.", 400);
        }

        var latest = FindLatestReceiptEntry(doc.RootElement, productId);
        if (latest is null)
        {
            throw new AppException("No matching subscription in Apple receipt.", 400);
        }

        var expiresMs = ReadLong(latest.Value, "expires_date_ms");
        var originalId = ReadString(latest.Value, "original_transaction_id")
            ?? ReadString(latest.Value, "transaction_id");

        var periodEnd = expiresMs > 0
            ? DateTimeOffset.FromUnixTimeMilliseconds(expiresMs).UtcDateTime
            : (DateTime?)null;

        return new MobileStoreSubscriptionDetails
        {
            PlanCode = planCode,
            BillingCycle = billingCycle,
            ProviderSubscriptionId = originalId ?? receiptData,
            IsActive = periodEnd is null || periodEnd > DateTime.UtcNow,
            AutoRenewEnabled = true,
            PeriodEnd = periodEnd,
            LatestTransactionId = ReadString(latest.Value, "transaction_id"),
        };
    }

    private static JsonElement? FindLatestReceiptEntry(JsonElement root, string productId)
    {
        if (!root.TryGetProperty("latest_receipt_info", out var entries))
        {
            return null;
        }

        JsonElement? best = null;
        long bestExpires = 0;
        foreach (var entry in entries.EnumerateArray())
        {
            if (!entry.TryGetProperty("product_id", out var pid)
                || !string.Equals(pid.GetString(), productId, StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            var expires = ReadLong(entry, "expires_date_ms");
            if (expires >= bestExpires)
            {
                bestExpires = expires;
                best = entry;
            }
        }

        return best;
    }

    private static JsonElement DecodeAppleJwsPayload(string jws)
    {
        var parts = jws.Split('.');
        if (parts.Length < 2)
        {
            throw new AppException("Invalid Apple JWS.", 502);
        }

        var json = Encoding.UTF8.GetString(DecodeBase64Url(parts[1]));
        using var doc = JsonDocument.Parse(json);
        return doc.RootElement.Clone();
    }

    private static byte[] DecodeBase64Url(string segment)
    {
        var padded = segment.Replace('-', '+').Replace('_', '/');
        padded = padded.PadRight(padded.Length + (4 - padded.Length % 4) % 4, '=');
        return Convert.FromBase64String(padded);
    }

    private static string? ReadString(JsonElement el, string name) =>
        el.TryGetProperty(name, out var prop) ? prop.GetString() : null;

    private static long ReadLong(JsonElement el, string name)
    {
        if (!el.TryGetProperty(name, out var prop))
        {
            return 0;
        }

        return prop.ValueKind switch
        {
            JsonValueKind.Number => prop.GetInt64(),
            JsonValueKind.String when long.TryParse(prop.GetString(), out var n) => n,
            _ => 0,
        };
    }
}
