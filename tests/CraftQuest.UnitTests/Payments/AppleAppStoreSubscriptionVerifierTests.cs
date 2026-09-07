using System.Net;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.Json;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Options;
using CraftQuest.Infrastructure.Services.Payments;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;

namespace CraftQuest.UnitTests.Payments;

public class AppleAppStoreSubscriptionVerifierTests
{
    [Fact]
    public async Task VerifyViaReceiptAsync_ProductionEnvironment_21007_RetriesSandbox()
    {
        var handler = new QueueHttpMessageHandler();
        handler.Enqueue(_ => JsonResponse(HttpStatusCode.OK, """{"status":21007}"""));
        handler.Enqueue(_ => JsonResponse(
            HttpStatusCode.OK,
            """
            {
              "status": 0,
              "latest_receipt_info": [
                {
                  "product_id": "craftquest_pro_monthly",
                  "transaction_id": "sandbox-tx-1",
                  "original_transaction_id": "sandbox-otx-1",
                  "expires_date_ms": "4102444800000"
                }
              ]
            }
            """));

        var verifier = CreateVerifier(handler, new MobileStoreOptions
        {
            AppleEnvironment = "Production",
            AppleSharedSecret = "shared-secret",
        });

        var result = await verifier.VerifyAsync(
            "craftquest_pro_monthly",
            "receipt-data",
            transactionId: null,
            CancellationToken.None);

        Assert.Equal("pro", result.PlanCode);
        Assert.Equal("sandbox-otx-1", result.ProviderSubscriptionId);
        Assert.Equal(2, handler.Requests.Count);
        Assert.Equal(
            "https://buy.itunes.apple.com/verifyReceipt",
            handler.Requests[0].RequestUri!.ToString());
        Assert.Equal(
            "https://sandbox.itunes.apple.com/verifyReceipt",
            handler.Requests[1].RequestUri!.ToString());
    }

    [Fact]
    public async Task VerifyViaReceiptAsync_SandboxEnvironment_21008_RetriesProduction()
    {
        var handler = new QueueHttpMessageHandler();
        handler.Enqueue(_ => JsonResponse(HttpStatusCode.OK, """{"status":21008}"""));
        handler.Enqueue(_ => JsonResponse(
            HttpStatusCode.OK,
            """
            {
              "status": 0,
              "latest_receipt_info": [
                {
                  "product_id": "craftquest_ai_credits_50",
                  "transaction_id": "prod-tx-1",
                  "original_transaction_id": "prod-tx-1",
                  "purchase_date_ms": "1700000000000"
                }
              ]
            }
            """));

        var verifier = CreateVerifier(handler, new MobileStoreOptions
        {
            AppleEnvironment = "Sandbox",
            AppleSharedSecret = "shared-secret",
        });

        var result = await verifier.VerifyConsumableAsync(
            "craftquest_ai_credits_50",
            "receipt-data",
            transactionId: null,
            CancellationToken.None);

        Assert.True(result.IsValid);
        Assert.Equal("prod-tx-1", result.TransactionId);
        Assert.Equal(2, handler.Requests.Count);
        Assert.Contains("sandbox.itunes.apple.com", handler.Requests[0].RequestUri!.Host);
        Assert.Contains("buy.itunes.apple.com", handler.Requests[1].RequestUri!.Host);
    }

    [Fact]
    public async Task VerifyViaReceiptAsync_21007WithoutRetryWhenAlreadySandbox_Throws()
    {
        var handler = new QueueHttpMessageHandler();
        handler.Enqueue(_ => JsonResponse(HttpStatusCode.OK, """{"status":21007}"""));

        var verifier = CreateVerifier(handler, new MobileStoreOptions
        {
            AppleEnvironment = "Sandbox",
            AppleSharedSecret = "shared-secret",
        });

        var exception = await Assert.ThrowsAsync<AppException>(() =>
            verifier.VerifyAsync(
                "craftquest_pro_monthly",
                "receipt-data",
                transactionId: null,
                CancellationToken.None));

        Assert.Equal(400, exception.StatusCode);
        Assert.Contains("21007", exception.Message, StringComparison.Ordinal);
        Assert.Single(handler.Requests);
    }

    [Fact]
    public async Task VerifyViaAppStoreServerApi_Production404_RetriesSandbox()
    {
        var keyPath = WriteTemporaryPrivateKey();
        try
        {
            var handler = new QueueHttpMessageHandler();
            handler.Enqueue(_ => JsonResponse(
                HttpStatusCode.NotFound,
                """{"errorCode":4040010,"errorMessage":"Transaction id not found."}"""));
            handler.Enqueue(_ => JsonResponse(
                HttpStatusCode.OK,
                $$"""{"signedTransactionInfo":"{{BuildFakeSignedTransactionInfo(
                    "craftquest_pro_monthly",
                    "tx-sandbox-1",
                    "otx-sandbox-1",
                    4_102_444_800_000)}}"}"""));

            var verifier = CreateVerifier(handler, new MobileStoreOptions
            {
                AppleEnvironment = "Production",
                AppleIssuerId = "issuer-id",
                AppleKeyId = "key-id",
                AppleBundleId = "com.craftquestai.craftquestaiApp",
                ApplePrivateKeyPath = keyPath,
            });

            var result = await verifier.VerifyAsync(
                "craftquest_pro_monthly",
                purchaseToken: "ignored",
                transactionId: "tx-sandbox-1",
                CancellationToken.None);

            Assert.Equal("pro", result.PlanCode);
            Assert.Equal("otx-sandbox-1", result.ProviderSubscriptionId);
            Assert.Equal(2, handler.Requests.Count);
            Assert.Contains("api.storekit.itunes.apple.com", handler.Requests[0].RequestUri!.Host);
            Assert.Contains(
                "api.storekit-sandbox.itunes.apple.com",
                handler.Requests[1].RequestUri!.Host);
        }
        finally
        {
            File.Delete(keyPath);
        }
    }

    [Fact]
    public async Task VerifyViaAppStoreServerApi_SandboxSuccess_NoFallbackRequest()
    {
        var keyPath = WriteTemporaryPrivateKey();
        try
        {
            var handler = new QueueHttpMessageHandler();
            handler.Enqueue(_ => JsonResponse(
                HttpStatusCode.OK,
                $$"""{"signedTransactionInfo":"{{BuildFakeSignedTransactionInfo(
                    "craftquest_ai_credits_50",
                    "tx-1",
                    "tx-1",
                    0)}}"}"""));

            var verifier = CreateVerifier(handler, new MobileStoreOptions
            {
                AppleEnvironment = "Sandbox",
                AppleIssuerId = "issuer-id",
                AppleKeyId = "key-id",
                AppleBundleId = "com.craftquestai.craftquestaiApp",
                ApplePrivateKeyPath = keyPath,
            });

            var result = await verifier.VerifyConsumableAsync(
                "craftquest_ai_credits_50",
                purchaseToken: "ignored",
                transactionId: "tx-1",
                CancellationToken.None);

            Assert.True(result.IsValid);
            Assert.Equal("tx-1", result.TransactionId);
            Assert.Single(handler.Requests);
            Assert.Contains(
                "api.storekit-sandbox.itunes.apple.com",
                handler.Requests[0].RequestUri!.Host);
        }
        finally
        {
            File.Delete(keyPath);
        }
    }

    [Fact]
    public async Task VerifyAsync_ValidStoreKit2Jws_ActivatesWithoutAppleServerApiKeys()
    {
        var expiresMs = DateTimeOffset.UtcNow.AddDays(30).ToUnixTimeMilliseconds();
        var jws = BuildSignedTransactionJws(
            productId: "craftquest_pro_monthly",
            transactionId: "tx-jws-1",
            originalTransactionId: "otx-jws-1",
            expiresDate: expiresMs,
            bundleId: "com.craftquestai.craftquestaiApp");

        var handler = new QueueHttpMessageHandler();
        var verifier = CreateVerifier(handler, new MobileStoreOptions
        {
            AppleBundleId = "com.craftquestai.craftquestaiApp",
        });

        var result = await verifier.VerifyAsync(
            "craftquest_pro_monthly",
            jws,
            transactionId: "tx-jws-1",
            CancellationToken.None);

        Assert.Equal("pro", result.PlanCode);
        Assert.Equal("monthly", result.BillingCycle);
        Assert.Equal("otx-jws-1", result.ProviderSubscriptionId);
        Assert.Equal("tx-jws-1", result.LatestTransactionId);
        Assert.True(result.IsActive);
        Assert.Empty(handler.Requests);
    }

    [Fact]
    public async Task VerifyAsync_UnsignedJwsWithoutAppleKeys_ThrowsNotConfigured()
    {
        var verifier = CreateVerifier(new QueueHttpMessageHandler(), new MobileStoreOptions
        {
            AppleBundleId = "com.craftquestai.craftquestaiApp",
        });

        var ex = await Assert.ThrowsAsync<AppException>(() => verifier.VerifyAsync(
            "craftquest_pro_monthly",
            BuildFakeSignedTransactionInfo(
                "craftquest_pro_monthly",
                "tx-1",
                "otx-1",
                4_102_444_800_000),
            transactionId: "tx-1",
            CancellationToken.None));

        Assert.Equal(503, ex.StatusCode);
    }

    [Fact]
    public async Task VerifyConsumableAsync_ValidStoreKit2Jws_DoesNotCallAppStoreApi()
    {
        var jws = BuildSignedTransactionJws(
            productId: "craftquest_ai_credits_50",
            transactionId: "tx-credit-1",
            originalTransactionId: "tx-credit-1",
            expiresDate: 0,
            bundleId: "com.craftquestai.craftquestaiApp");

        var handler = new QueueHttpMessageHandler();
        var verifier = CreateVerifier(handler, new MobileStoreOptions
        {
            AppleBundleId = "com.craftquestai.craftquestaiApp",
        });

        var result = await verifier.VerifyConsumableAsync(
            "craftquest_ai_credits_50",
            jws,
            transactionId: "tx-credit-1",
            CancellationToken.None);

        Assert.True(result.IsValid);
        Assert.Equal("tx-credit-1", result.TransactionId);
        Assert.Empty(handler.Requests);
    }

    [Fact]
    public void IsAppleSubscriptionCurrentlyActive_UnixSecondsExpiry_IsActive()
    {
        var expires = DateTimeOffset.UtcNow.AddDays(30).ToUnixTimeSeconds();
        using var doc = JsonDocument.Parse($$"""{"expiresDate": {{expires}} }""");
        Assert.True(
            AppleAppStoreSubscriptionVerifier.IsAppleSubscriptionCurrentlyActive(
                doc.RootElement,
                DateTime.UtcNow));
    }

    [Fact]
    public void IsAppleSubscriptionCurrentlyActive_ExpiredButFreshPurchase_IsActive()
    {
        var now = DateTime.UtcNow;
        var expires = new DateTimeOffset(now.AddMinutes(-20)).ToUnixTimeMilliseconds();
        var purchased = new DateTimeOffset(now.AddMinutes(-1)).ToUnixTimeMilliseconds();
        using var doc = JsonDocument.Parse(
            $$"""{"expiresDate": {{expires}}, "purchaseDate": {{purchased}} }""");
        Assert.True(
            AppleAppStoreSubscriptionVerifier.IsAppleSubscriptionCurrentlyActive(
                doc.RootElement,
                now));
    }

    [Fact]
    public void IsAppleSubscriptionCurrentlyActive_StaleExpired_IsInactive()
    {
        var now = DateTime.UtcNow;
        var expires = new DateTimeOffset(now.AddHours(-2)).ToUnixTimeMilliseconds();
        var purchased = new DateTimeOffset(now.AddHours(-3)).ToUnixTimeMilliseconds();
        using var doc = JsonDocument.Parse(
            $$"""{"expiresDate": {{expires}}, "purchaseDate": {{purchased}} }""");
        Assert.False(
            AppleAppStoreSubscriptionVerifier.IsAppleSubscriptionCurrentlyActive(
                doc.RootElement,
                now));
    }

    [Fact]
    public async Task VerifyAsync_TeacherJwsWithPastSandboxExpiry_IsActiveWhenFresh()
    {
        var now = DateTimeOffset.UtcNow;
        var jws = BuildSignedTransactionJws(
            productId: "craftquest_teacher_monthly",
            transactionId: "tx-teacher-1",
            originalTransactionId: "otx-pro-1",
            expiresDate: now.AddMinutes(-10).ToUnixTimeMilliseconds(),
            bundleId: "com.craftquestai.craftquestaiApp",
            purchaseDate: now.AddMinutes(-1).ToUnixTimeMilliseconds());

        var handler = new QueueHttpMessageHandler();
        var verifier = CreateVerifier(handler, new MobileStoreOptions
        {
            AppleBundleId = "com.craftquestai.craftquestaiApp",
        });

        var result = await verifier.VerifyAsync(
            "craftquest_teacher_monthly",
            jws,
            transactionId: "tx-teacher-1",
            CancellationToken.None);

        Assert.Equal("teacher", result.PlanCode);
        Assert.True(result.IsActive);
        Assert.True(result.PeriodEnd > DateTime.UtcNow);
        Assert.Empty(handler.Requests);
    }

    private static AppleAppStoreSubscriptionVerifier CreateVerifier(
        QueueHttpMessageHandler handler,
        MobileStoreOptions mobileOptions)
    {
        var paymentOptions = Options.Create(new PaymentOptions
        {
            UseMockPayments = false,
            Mobile = mobileOptions,
            PlanProducts = new Dictionary<string, PlanProductMapping>
            {
                ["pro"] = new()
                {
                    AppStoreProductId = "craftquest_pro_monthly",
                    AppStoreAnnualProductId = "craftquest_pro_annual",
                },
                ["teacher"] = new()
                {
                    AppStoreProductId = "craftquest_teacher_monthly",
                    AppStoreAnnualProductId = "craftquest_teacher_annual",
                },
            },
        });

        var factory = new NamedHttpClientFactoryStub(handler);
        return new AppleAppStoreSubscriptionVerifier(factory, paymentOptions);
    }

    private static HttpResponseMessage JsonResponse(HttpStatusCode statusCode, string json) =>
        new(statusCode)
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json"),
        };

    private static string WriteTemporaryPrivateKey()
    {
        using var ecdsa = ECDsa.Create(ECCurve.NamedCurves.nistP256);
        var pkcs8 = ecdsa.ExportPkcs8PrivateKey();
        var base64 = Convert.ToBase64String(pkcs8);
        var path = Path.Combine(Path.GetTempPath(), $"craftquest-apple-{Guid.NewGuid():N}.p8");
        File.WriteAllText(path, $"-----BEGIN PRIVATE KEY-----\n{base64}\n-----END PRIVATE KEY-----");
        return path;
    }

    private static string BuildFakeSignedTransactionInfo(
        string productId,
        string transactionId,
        string originalTransactionId,
        long expiresDate)
    {
        var payloadJson = JsonSerializer.Serialize(new
        {
            productId,
            transactionId,
            originalTransactionId,
            expiresDate,
        });
        var payloadSegment = Base64UrlEncode(Encoding.UTF8.GetBytes(payloadJson));
        return $"eyJhbGciOiJFUzI1NiJ9.{payloadSegment}.signature";
    }

    private static string BuildSignedTransactionJws(
        string productId,
        string transactionId,
        string originalTransactionId,
        long expiresDate,
        string bundleId,
        long purchaseDate = 0)
    {
        using var ecdsa = ECDsa.Create(ECCurve.NamedCurves.nistP256);
        var request = new CertificateRequest(
            "CN=Apple Root CA TEST",
            ecdsa,
            HashAlgorithmName.SHA256);
        using var cert = request.CreateSelfSigned(
            DateTimeOffset.UtcNow.AddDays(-1),
            DateTimeOffset.UtcNow.AddYears(1));

        var header = new JwtHeader(
            new SigningCredentials(new ECDsaSecurityKey(ecdsa), SecurityAlgorithms.EcdsaSha256));
        header["x5c"] = new[] { Convert.ToBase64String(cert.RawData) };

        var payload = new JwtPayload
        {
            { "productId", productId },
            { "transactionId", transactionId },
            { "originalTransactionId", originalTransactionId },
            { "expiresDate", expiresDate },
            { "bundleId", bundleId },
        };
        if (purchaseDate > 0)
        {
            payload["purchaseDate"] = purchaseDate;
        }

        return new JwtSecurityTokenHandler().WriteToken(new JwtSecurityToken(header, payload));
    }

    private static string Base64UrlEncode(byte[] bytes) =>
        Convert.ToBase64String(bytes)
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');

    private sealed class QueueHttpMessageHandler : HttpMessageHandler
    {
        private readonly Queue<Func<HttpRequestMessage, HttpResponseMessage>> _responses = new();

        public IList<HttpRequestMessage> Requests { get; } = new List<HttpRequestMessage>();

        public void Enqueue(Func<HttpRequestMessage, HttpResponseMessage> factory) =>
            _responses.Enqueue(factory);

        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            Requests.Add(request);
            if (_responses.Count == 0)
            {
                throw new InvalidOperationException("No queued HTTP response for request.");
            }

            return Task.FromResult(_responses.Dequeue()(request));
        }
    }

    private sealed class NamedHttpClientFactoryStub(QueueHttpMessageHandler handler) : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) => new(handler, disposeHandler: false);
    }
}
