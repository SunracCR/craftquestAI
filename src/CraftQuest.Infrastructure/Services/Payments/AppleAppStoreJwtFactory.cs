using System.IdentityModel.Tokens.Jwt;
using System.Security.Cryptography;
using Microsoft.IdentityModel.Tokens;

namespace CraftQuest.Infrastructure.Services.Payments;

internal static class AppleAppStoreJwtFactory
{
    public static string CreateToken(
        string issuerId,
        string keyId,
        string bundleId,
        string privateKeyPem)
    {
        using var ecdsa = ECDsa.Create();
        var keyBytes = ReadPkcs8FromPem(privateKeyPem);
        ecdsa.ImportPkcs8PrivateKey(keyBytes, out _);

        var credentials = new SigningCredentials(
            new ECDsaSecurityKey(ecdsa) { KeyId = keyId },
            SecurityAlgorithms.EcdsaSha256);

        var now = DateTime.UtcNow;
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
