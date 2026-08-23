using System.Net;
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
    private const string ProductionReceiptVerifyUrl = "https://buy.itunes.apple.com/verifyReceipt";
    private const string SandboxReceiptVerifyUrl = "https://sandbox.itunes.apple.com/verifyReceipt";
    private const string ProductionStoreKitApiBaseUrl = "https://api.storekit.itunes.apple.com";
    private const string SandboxStoreKitApiBaseUrl = "https://api.storekit-sandbox.itunes.apple.com";

    /// <summary>Sandbox receipt sent to production verifyReceipt endpoint.</summary>
    private const int ReceiptStatusSandboxReceiptOnProduction = 21007;

    /// <summary>Production receipt sent to sandbox verifyReceipt endpoint.</summary>
    private const int ReceiptStatusProductionReceiptOnSandbox = 21008;

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

    public async Task<MobileStoreProductDetails> VerifyConsumableAsync(
        string productId,
        string purchaseToken,
        string? transactionId,
        CancellationToken cancellationToken)
    {
        var mobile = options.Value.Mobile;

        if (!string.IsNullOrWhiteSpace(transactionId)
            && !string.IsNullOrWhiteSpace(mobile.AppleIssuerId)
            && !string.IsNullOrWhiteSpace(mobile.AppleKeyId)
            && !string.IsNullOrWhiteSpace(mobile.ApplePrivateKeyPath)
            && File.Exists(mobile.ApplePrivateKeyPath))
        {
            return await VerifyConsumableViaAppStoreServerApiAsync(
                productId,
                transactionId,
                mobile,
                cancellationToken);
        }

        if (!string.IsNullOrWhiteSpace(mobile.AppleSharedSecret))
        {
            return await VerifyConsumableViaReceiptAsync(
                purchaseToken,
                productId,
                mobile,
                cancellationToken);
        }

        throw new AppException(
            "App Store is not configured. Set Apple Issuer/Key/PrivateKey or AppleSharedSecret.",
            503);
    }

    private async Task<MobileStoreProductDetails> VerifyConsumableViaAppStoreServerApiAsync(
        string expectedProductId,
        string transactionId,
        MobileStoreOptions mobile,
        CancellationToken cancellationToken)
    {
        var jwt = await CreateAppStoreJwtAsync(mobile, cancellationToken);
        using var doc = await GetTransactionDocumentWithEnvironmentFallbackAsync(
            transactionId,
            jwt,
            mobile,
            cancellationToken);

        if (!doc.RootElement.TryGetProperty("signedTransactionInfo", out var signedInfoEl))
        {
            throw new AppException("App Store response missing signedTransactionInfo.", 502);
        }

        var payload = DecodeAppleJwsPayload(signedInfoEl.GetString()!);
        var storeProductId = ReadString(payload, "productId");
        if (!string.Equals(storeProductId, expectedProductId, StringComparison.OrdinalIgnoreCase))
        {
            throw new AppException(
                "App Store transaction product does not match the requested pack.",
                400,
                "STORE_PURCHASE_INVALID");
        }

        var resolvedTransactionId = ReadString(payload, "transactionId") ?? transactionId;
        return new MobileStoreProductDetails
        {
            IsValid = true,
            TransactionId = resolvedTransactionId,
        };
    }

    private async Task<MobileStoreProductDetails> VerifyConsumableViaReceiptAsync(
        string receiptData,
        string productId,
        MobileStoreOptions mobile,
        CancellationToken cancellationToken)
    {
        using var doc = await PostVerifyReceiptDocumentWithEnvironmentFallbackAsync(
            receiptData,
            mobile,
            cancellationToken);

        var latest = FindLatestConsumableReceiptEntry(doc.RootElement, productId);
        if (latest is null)
        {
            throw new AppException("No matching consumable purchase in Apple receipt.", 400);
        }

        var transactionId = ReadString(latest.Value, "transaction_id")
            ?? ReadString(latest.Value, "original_transaction_id")
            ?? receiptData;

        return new MobileStoreProductDetails
        {
            IsValid = true,
            TransactionId = transactionId,
        };
    }

    private async Task<MobileStoreSubscriptionDetails> VerifyViaAppStoreServerApiAsync(
        string productId,
        string planCode,
        string billingCycle,
        string transactionId,
        MobileStoreOptions mobile,
        CancellationToken cancellationToken)
    {
        var jwt = await CreateAppStoreJwtAsync(mobile, cancellationToken);
        using var doc = await GetTransactionDocumentWithEnvironmentFallbackAsync(
            transactionId,
            jwt,
            mobile,
            cancellationToken);

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
        using var doc = await PostVerifyReceiptDocumentWithEnvironmentFallbackAsync(
            receiptData,
            mobile,
            cancellationToken);

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

    private async Task<JsonDocument> PostVerifyReceiptDocumentWithEnvironmentFallbackAsync(
        string receiptData,
        MobileStoreOptions mobile,
        CancellationToken cancellationToken)
    {
        var useProductionFirst = mobile.AppleEnvironment.Equals(
            "Production",
            StringComparison.OrdinalIgnoreCase);
        var primaryUrl = useProductionFirst ? ProductionReceiptVerifyUrl : SandboxReceiptVerifyUrl;
        var fallbackUrl = useProductionFirst ? SandboxReceiptVerifyUrl : ProductionReceiptVerifyUrl;

        var primaryDoc = await PostVerifyReceiptDocumentAsync(
            receiptData,
            mobile,
            primaryUrl,
            cancellationToken);
        var status = primaryDoc.RootElement.GetProperty("status").GetInt32();
        if (status == 0)
        {
            return primaryDoc;
        }

        if (status == ReceiptStatusSandboxReceiptOnProduction
            && primaryUrl == ProductionReceiptVerifyUrl)
        {
            primaryDoc.Dispose();
            var fallbackDoc = await PostVerifyReceiptDocumentAsync(
                receiptData,
                mobile,
                fallbackUrl,
                cancellationToken);
            var fallbackStatus = fallbackDoc.RootElement.GetProperty("status").GetInt32();
            if (fallbackStatus == 0)
            {
                return fallbackDoc;
            }

            fallbackDoc.Dispose();
            throw new AppException($"Apple verifyReceipt status {fallbackStatus}.", 400);
        }

        if (status == ReceiptStatusProductionReceiptOnSandbox
            && primaryUrl == SandboxReceiptVerifyUrl)
        {
            primaryDoc.Dispose();
            var fallbackDoc = await PostVerifyReceiptDocumentAsync(
                receiptData,
                mobile,
                fallbackUrl,
                cancellationToken);
            var fallbackStatus = fallbackDoc.RootElement.GetProperty("status").GetInt32();
            if (fallbackStatus == 0)
            {
                return fallbackDoc;
            }

            fallbackDoc.Dispose();
            throw new AppException($"Apple verifyReceipt status {fallbackStatus}.", 400);
        }

        primaryDoc.Dispose();
        throw new AppException($"Apple verifyReceipt status {status}.", 400);
    }

    private async Task<JsonDocument> PostVerifyReceiptDocumentAsync(
        string receiptData,
        MobileStoreOptions mobile,
        string verifyUrl,
        CancellationToken cancellationToken)
    {
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

        return JsonDocument.Parse(body);
    }

    private async Task<JsonDocument> GetTransactionDocumentWithEnvironmentFallbackAsync(
        string transactionId,
        string jwt,
        MobileStoreOptions mobile,
        CancellationToken cancellationToken)
    {
        var useProductionFirst = mobile.AppleEnvironment.Equals(
            "Production",
            StringComparison.OrdinalIgnoreCase);
        var primaryBaseUrl = useProductionFirst
            ? ProductionStoreKitApiBaseUrl
            : SandboxStoreKitApiBaseUrl;
        var fallbackBaseUrl = useProductionFirst
            ? SandboxStoreKitApiBaseUrl
            : ProductionStoreKitApiBaseUrl;

        var (primaryStatusCode, primaryBody) = await GetTransactionAsync(
            transactionId,
            jwt,
            primaryBaseUrl,
            cancellationToken);
        if ((int)primaryStatusCode >= 200 && (int)primaryStatusCode <= 299)
        {
            return JsonDocument.Parse(primaryBody);
        }

        if (ShouldRetryTransactionLookupInAlternateEnvironment(primaryStatusCode, primaryBody))
        {
            var (fallbackStatusCode, fallbackBody) = await GetTransactionAsync(
                transactionId,
                jwt,
                fallbackBaseUrl,
                cancellationToken);
            if ((int)fallbackStatusCode >= 200 && (int)fallbackStatusCode <= 299)
            {
                return JsonDocument.Parse(fallbackBody);
            }

            throw new AppException($"App Store transaction lookup failed: {fallbackBody}", 502);
        }

        throw new AppException($"App Store transaction lookup failed: {primaryBody}", 502);
    }

    private async Task<(HttpStatusCode StatusCode, string Body)> GetTransactionAsync(
        string transactionId,
        string jwt,
        string baseUrl,
        CancellationToken cancellationToken)
    {
        var client = httpClientFactory.CreateClient(nameof(AppleAppStoreSubscriptionVerifier));
        using var request = new HttpRequestMessage(
            HttpMethod.Get,
            $"{baseUrl}/inApps/v1/transactions/{transactionId}");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", jwt);

        using var response = await client.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        return (response.StatusCode, body);
    }

    private static bool ShouldRetryTransactionLookupInAlternateEnvironment(
        HttpStatusCode statusCode,
        string body)
    {
        if (statusCode == HttpStatusCode.NotFound)
        {
            return true;
        }

        return body.Contains("4040010", StringComparison.Ordinal)
            || body.Contains("TransactionIdNotFound", StringComparison.OrdinalIgnoreCase)
            || body.Contains("TRANSACTION_ID_NOT_FOUND", StringComparison.OrdinalIgnoreCase);
    }

    private static async Task<string> CreateAppStoreJwtAsync(
        MobileStoreOptions mobile,
        CancellationToken cancellationToken)
    {
        var pem = await File.ReadAllTextAsync(mobile.ApplePrivateKeyPath, cancellationToken);
        return AppleAppStoreJwtFactory.CreateToken(
            mobile.AppleIssuerId,
            mobile.AppleKeyId,
            mobile.AppleBundleId,
            pem);
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

    private static JsonElement? FindLatestConsumableReceiptEntry(JsonElement root, string productId)
    {
        if (!root.TryGetProperty("latest_receipt_info", out var entries))
        {
            return null;
        }

        JsonElement? best = null;
        long bestPurchased = 0;
        foreach (var entry in entries.EnumerateArray())
        {
            if (!entry.TryGetProperty("product_id", out var pid)
                || !string.Equals(pid.GetString(), productId, StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            var purchased = ReadLong(entry, "purchase_date_ms");
            if (purchased >= bestPurchased)
            {
                bestPurchased = purchased;
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
