using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using CraftQuest.Application.Models.Auth;
using CraftQuest.Application.Options;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace CraftQuest.Infrastructure.Security;

public class JwtTokenService(IOptions<JwtOptions> options)
{
    private readonly JwtOptions _options = options.Value;

    public AuthTokensDto CreateTokenPair(Guid userId, string email, IReadOnlyList<string> roles)
    {
        var accessExpires = DateTime.UtcNow.AddMinutes(_options.AccessTokenMinutes);
        var refreshExpires = DateTime.UtcNow.AddDays(_options.RefreshTokenDays);

        return new AuthTokensDto
        {
            AccessToken = CreateToken(userId, email, roles, accessExpires, "access"),
            RefreshToken = CreateToken(userId, email, roles, refreshExpires, "refresh"),
            AccessTokenExpiresAt = accessExpires,
            RefreshTokenExpiresAt = refreshExpires,
        };
    }

    public ClaimsPrincipal? ValidateToken(string token, string expectedTokenType)
    {
        var parameters = BuildValidationParameters();
        var handler = new JwtSecurityTokenHandler();

        try
        {
            var principal = handler.ValidateToken(token, parameters, out var validatedToken);
            if (validatedToken is not JwtSecurityToken jwt
                || !string.Equals(jwt.Claims.FirstOrDefault(c => c.Type == "token_type")?.Value, expectedTokenType, StringComparison.Ordinal))
            {
                return null;
            }

            return principal;
        }
        catch
        {
            return null;
        }
    }

    private string CreateToken(
        Guid userId,
        string email,
        IReadOnlyList<string> roles,
        DateTime expiresAt,
        string tokenType)
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new(JwtRegisteredClaimNames.Email, email),
            new("token_type", tokenType),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
        };

        claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role)));

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.SecretKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            expires: expiresAt,
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private TokenValidationParameters BuildValidationParameters() => new()
    {
        ValidateIssuer = true,
        ValidIssuer = _options.Issuer,
        ValidateAudience = true,
        ValidAudience = _options.Audience,
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.SecretKey)),
        ValidateLifetime = true,
        ClockSkew = TimeSpan.FromMinutes(1),
    };
}
