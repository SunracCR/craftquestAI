using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Options;
using CraftQuest.Infrastructure.Services.Payments;
using Microsoft.Extensions.Options;

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
