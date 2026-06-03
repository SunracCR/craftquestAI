using System.IdentityModel.Tokens.Jwt;
using System.Text.Json;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Options;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace CraftQuest.Infrastructure.Security;

public sealed class AppleIdTokenValidator(
    IHttpClientFactory httpClientFactory,
    IMemoryCache memoryCache,
    IOptions<ExternalAuthOptions> options) : IAppleIdTokenValidator
{
    private const string AppleJwksUrl = "https://appleid.apple.com/auth/keys";
    private const string AppleIssuer = "https://appleid.apple.com";
    private static readonly TimeSpan JwksCacheDuration = TimeSpan.FromHours(12);

    public async Task<ExternalAuthUserInfo> ValidateAsync(
        string idToken,
        CancellationToken cancellationToken = default)
    {
        var audiences = GetAudiences();
        if (audiences.Count == 0)
        {
            throw new AuthException(
                "Apple sign-in is not configured.",
                503,
                "APPLE_AUTH_NOT_CONFIGURED");
        }

        var handler = new JwtSecurityTokenHandler();
        JwtSecurityToken unverified;
        try
        {
            unverified = handler.ReadJwtToken(idToken);
        }
        catch (Exception)
        {
            throw new AuthException("Invalid Apple token.", 401, "INVALID_APPLE_TOKEN");
        }

        var kid = unverified.Header.Kid;
        if (string.IsNullOrWhiteSpace(kid))
        {
            throw new AuthException("Invalid Apple token header.", 401, "INVALID_APPLE_TOKEN");
        }

        var signingKey = await GetSigningKeyAsync(kid, cancellationToken);
        var validationParameters = new TokenValidationParameters
        {
            ValidIssuer = AppleIssuer,
            ValidAudiences = audiences,
            IssuerSigningKey = signingKey,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(2),
        };

        try
        {
            handler.ValidateToken(idToken, validationParameters, out var validatedToken);
            var jwt = (JwtSecurityToken)validatedToken;
            var email = jwt.Claims.FirstOrDefault(c => c.Type == "email")?.Value;
            var emailVerified = jwt.Claims.FirstOrDefault(c => c.Type == "email_verified")?.Value == "true";
            var sub = jwt.Claims.First(c => c.Type == "sub").Value;

            return new ExternalAuthUserInfo(sub, email, null, emailVerified);
        }
        catch (SecurityTokenException ex)
        {
            throw new AuthException($"Invalid Apple token: {ex.Message}", 401, "INVALID_APPLE_TOKEN");
        }
    }

    private async Task<SecurityKey> GetSigningKeyAsync(string kid, CancellationToken cancellationToken)
    {
        var jwks = await memoryCache.GetOrCreateAsync(
            "apple-signin-jwks",
            async entry =>
            {
                entry.AbsoluteExpirationRelativeToNow = JwksCacheDuration;
                return await FetchJwksAsync(cancellationToken);
            }) ?? throw new AuthException("Unable to load Apple signing keys.", 503);

        if (!jwks.TryGetValue(kid, out var key))
        {
            memoryCache.Remove("apple-signin-jwks");
            jwks = await FetchJwksAsync(cancellationToken);
            if (!jwks.TryGetValue(kid, out key))
            {
                throw new AuthException("Apple signing key not found.", 401, "INVALID_APPLE_TOKEN");
            }
        }

        return key;
    }

    private async Task<Dictionary<string, SecurityKey>> FetchJwksAsync(CancellationToken cancellationToken)
    {
        var client = httpClientFactory.CreateClient(nameof(AppleIdTokenValidator));
        using var response = await client.GetAsync(AppleJwksUrl, cancellationToken);
        response.EnsureSuccessStatusCode();
        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        using var doc = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);

        var map = new Dictionary<string, SecurityKey>(StringComparer.Ordinal);
        if (!doc.RootElement.TryGetProperty("keys", out var keysEl))
        {
            return map;
        }

        foreach (var keyEl in keysEl.EnumerateArray())
        {
            var keyId = keyEl.GetProperty("kid").GetString();
            if (string.IsNullOrWhiteSpace(keyId))
            {
                continue;
            }

            var n = keyEl.GetProperty("n").GetString();
            var e = keyEl.GetProperty("e").GetString();
            if (n is null || e is null)
            {
                continue;
            }

            var rsa = new RsaSecurityKey(
                new System.Security.Cryptography.RSAParameters
                {
                    Modulus = Base64UrlEncoder.DecodeBytes(n),
                    Exponent = Base64UrlEncoder.DecodeBytes(e),
                })
            {
                KeyId = keyId,
            };

            map[keyId] = rsa;
        }

        return map;
    }

    private IReadOnlyList<string> GetAudiences()
    {
        var apple = options.Value.Apple;
        var list = new List<string>();
        if (!string.IsNullOrWhiteSpace(apple.BundleId))
        {
            list.Add(apple.BundleId.Trim());
        }

        if (!string.IsNullOrWhiteSpace(apple.ServicesId))
        {
            list.Add(apple.ServicesId!.Trim());
        }

        return list.Distinct(StringComparer.Ordinal).ToList();
    }
}
