using System.IdentityModel.Tokens.Jwt;
using System.Security.Cryptography;
using Microsoft.IdentityModel.Tokens;

namespace CraftQuest.Infrastructure.Services.Payments;

internal static class AppleAppStoreJwtFactory
{
    private static readonly object CacheLock = new();
    private static string? _cachedToken;
    private static string? _cacheKey;
    private static DateTime _cachedTokenExpiresAtUtc;

    /// <summary>Clears the in-memory JWT cache (for tests).</summary>
    internal static void ClearCacheForTesting()
    {
        lock (CacheLock)
        {
            _cachedToken = null;
            _cacheKey = null;
            _cachedTokenExpiresAtUtc = DateTime.MinValue;
        }
    }

    public static string CreateToken(
        string issuerId,
        string keyId,
        string bundleId,
        string privateKeyPem)
    {
        var cacheKey = $"{issuerId}|{keyId}|{bundleId}";
        var now = DateTime.UtcNow;

        lock (CacheLock)
        {
            if (_cachedToken is not null
                && _cacheKey == cacheKey
                && now < _cachedTokenExpiresAtUtc.AddMinutes(-1))
            {
                return _cachedToken;
            }
        }

        var token = CreateSignedToken(issuerId, keyId, bundleId, privateKeyPem, now);

        lock (CacheLock)
        {
            _cachedToken = token;
            _cacheKey = cacheKey;
            _cachedTokenExpiresAtUtc = now.AddMinutes(14);
        }

        return token;
    }

    private static string CreateSignedToken(
        string issuerId,
        string keyId,
        string bundleId,
        string privateKeyPem,
        DateTime now)
    {
        using var ecdsa = ECDsa.Create();
        var keyBytes = ReadPkcs8FromPem(privateKeyPem);
        ecdsa.ImportPkcs8PrivateKey(keyBytes, out _);

        var credentials = new SigningCredentials(
            new ECDsaSecurityKey(ecdsa) { KeyId = keyId },
            SecurityAlgorithms.EcdsaSha256)
        {
            CryptoProviderFactory = new CryptoProviderFactory { CacheSignatureProviders = false },
        };

        var descriptor = new SecurityTokenDescriptor
        {
            Issuer = issuerId,
            Audience = "appstoreconnect-v1",
            NotBefore = now,
            Expires = now.AddMinutes(15),
            SigningCredentials = credentials,
            Claims = new Dictionary<string, object>
            {
                ["bid"] = bundleId,
            },
        };

        var handler = new JwtSecurityTokenHandler();
        return handler.WriteToken(handler.CreateToken(descriptor));
    }

    private static byte[] ReadPkcs8FromPem(string pem)
    {
        var lines = pem
            .Replace("-----BEGIN PRIVATE KEY-----", string.Empty)
            .Replace("-----END PRIVATE KEY-----", string.Empty)
            .Replace("\r", string.Empty)
            .Replace("\n", string.Empty);
        return Convert.FromBase64String(lines);
    }
}
