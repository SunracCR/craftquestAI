using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.Json;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Options;
using Microsoft.Extensions.Options;
using System.IdentityModel.Tokens.Jwt;
using Microsoft.IdentityModel.Tokens;

namespace CraftQuest.Infrastructure.Services.Payments;

/// <summary>
/// Verifica notificaciones App Store Server (JWS con cadena x5c de Apple).
/// </summary>
public sealed class AppleAppStoreJwsVerifier(IOptions<PaymentOptions> options)
{
    public void VerifySignedPayload(string signedPayload)
    {
        if (!IsVerificationEnabled())
        {
            return;
        }

        if (!TryValidateJws(signedPayload, options.Value.Mobile.AppleBundleId))
        {
            throw new AppException("Apple notification signature verification failed.", 401);
        }
    }

    public static JsonElement DecodePayload(string signedPayload)
    {
        var parts = signedPayload.Split('.');
        if (parts.Length < 2)
        {
            throw new AppException("Invalid Apple JWS.", 400);
        }

        var json = Encoding.UTF8.GetString(DecodeBase64Url(parts[1]));
        using var doc = JsonDocument.Parse(json);
        return doc.RootElement.Clone();
    }

    private bool IsVerificationEnabled() =>
        !options.Value.UseMockPayments && options.Value.Webhooks.RequireVerification;

    internal static bool TryValidateJws(string jws, string? expectedBundleId)
    {
        if (string.IsNullOrWhiteSpace(jws))
        {
            return false;
        }

        try
        {
            var handler = new JwtSecurityTokenHandler();
            var token = handler.ReadJwtToken(jws);
            if (!token.Header.TryGetValue("x5c", out var x5cObj))
            {
                return false;
            }

            var x5cStrings = x5cObj switch
            {
                JsonElement { ValueKind: JsonValueKind.Array } arr =>
                    arr.EnumerateArray().Select(e => e.GetString()).Where(s => s != null).Cast<string>().ToList(),
                IEnumerable<object> objs => objs.Select(o => o.ToString()!).Where(s => !string.IsNullOrEmpty(s)).ToList(),
                _ => [],
            };

            if (x5cStrings.Count == 0)
            {
                return false;
            }

            var certs = x5cStrings
                .Select(raw => X509Certificate2.CreateFromPem(
                    $"-----BEGIN CERTIFICATE-----\n{raw}\n-----END CERTIFICATE-----"))
                .ToList();

            if (!ValidateCertificateChain(certs))
            {
                return false;
            }

            using var ecdsa = certs[0].GetECDsaPublicKey();
            if (ecdsa is null)
            {
                return false;
            }

            var validationParameters = new TokenValidationParameters
            {
                ValidateIssuer = false,
                ValidateAudience = false,
                ValidateLifetime = false,
                RequireSignedTokens = true,
                IssuerSigningKey = new ECDsaSecurityKey(ecdsa),
            };

            try
            {
                handler.ValidateToken(jws, validationParameters, out _);
            }
            catch (SecurityTokenException)
            {
                return false;
            }

            if (!string.IsNullOrWhiteSpace(expectedBundleId))
            {
                var payload = DecodePayload(jws);
                if (payload.TryGetProperty("bundleId", out var bundleEl)
                    && bundleEl.GetString() is { } bundleId
                    && !bundleId.Equals(expectedBundleId, StringComparison.Ordinal))
                {
                    return false;
                }
            }

            return true;
        }
        catch
        {
            return false;
        }
    }

    private static bool ValidateCertificateChain(IReadOnlyList<X509Certificate2> certs)
    {
        if (certs.Count == 0)
        {
            return false;
        }

        using var chain = new X509Chain();
        chain.ChainPolicy.RevocationMode = X509RevocationMode.NoCheck;
        chain.ChainPolicy.VerificationFlags =
            X509VerificationFlags.IgnoreNotTimeValid | X509VerificationFlags.AllowUnknownCertificateAuthority;

        for (var i = 1; i < certs.Count; i++)
        {
            chain.ChainPolicy.ExtraStore.Add(certs[i]);
        }

        var root = certs[^1];
        var hasAppleRoot = root.Subject.Contains("Apple", StringComparison.OrdinalIgnoreCase)
            || root.Issuer.Contains("Apple", StringComparison.OrdinalIgnoreCase);

        return hasAppleRoot && chain.Build(certs[0]);
    }

    private static byte[] DecodeBase64Url(string segment)
    {
        var padded = segment.Replace('-', '+').Replace('_', '/');
        padded = padded.PadRight(padded.Length + (4 - padded.Length % 4) % 4, '=');
        return Convert.FromBase64String(padded);
    }
}
