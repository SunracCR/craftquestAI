using System.Security.Cryptography;
using CraftQuest.Infrastructure.Services.Payments;

namespace CraftQuest.UnitTests.Payments;

public class AppleAppStoreJwtFactoryTests
{
    [Fact]
    public void CreateToken_RepeatedCalls_DoNotThrowObjectDisposedException()
    {
        AppleAppStoreJwtFactory.ClearCacheForTesting();
        var pem = CreateTestPrivateKeyPem();

        for (var i = 0; i < 50; i++)
        {
            var token = AppleAppStoreJwtFactory.CreateToken(
                issuerId: "issuer-id",
                keyId: "key-id",
                bundleId: "com.craftquestai.craftquestaiApp",
                privateKeyPem: pem);

            Assert.False(string.IsNullOrWhiteSpace(token));
        }
    }

    [Fact]
    public async Task CreateToken_ConcurrentCalls_DoNotThrowObjectDisposedException()
    {
        AppleAppStoreJwtFactory.ClearCacheForTesting();
        var pem = CreateTestPrivateKeyPem();

        var tasks = Enumerable.Range(0, 32).Select(_ => Task.Run(() =>
            AppleAppStoreJwtFactory.CreateToken(
                issuerId: "issuer-id",
                keyId: "key-id",
                bundleId: "com.craftquestai.craftquestaiApp",
                privateKeyPem: pem)));

        var tokens = await Task.WhenAll(tasks);

        Assert.All(tokens, token => Assert.False(string.IsNullOrWhiteSpace(token)));
    }

    [Fact]
    public void CreateToken_CachesToken_ForSameCredentials()
    {
        AppleAppStoreJwtFactory.ClearCacheForTesting();
        var pem = CreateTestPrivateKeyPem();

        var first = AppleAppStoreJwtFactory.CreateToken(
            "issuer-id",
            "key-id",
            "com.craftquestai.craftquestaiApp",
            pem);
        var second = AppleAppStoreJwtFactory.CreateToken(
            "issuer-id",
            "key-id",
            "com.craftquestai.craftquestaiApp",
            pem);

        Assert.Equal(first, second);
    }

    private static string CreateTestPrivateKeyPem()
    {
        using var ecdsa = ECDsa.Create(ECCurve.NamedCurves.nistP256);
        var pkcs8 = ecdsa.ExportPkcs8PrivateKey();
        var base64 = Convert.ToBase64String(pkcs8);
        return $"-----BEGIN PRIVATE KEY-----\n{base64}\n-----END PRIVATE KEY-----";
    }
}
