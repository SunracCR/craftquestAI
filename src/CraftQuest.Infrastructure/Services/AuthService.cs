using System.Security.Claims;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Auth;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class AuthService(
    CraftQuestDbContext dbContext,
    JwtTokenService jwtTokenService,
    IBillingService billingService) : IAuthService
{
    public async Task<AuthResponseDto> RegisterAsync(
        RegisterRequest request,
        CancellationToken cancellationToken = default)
    {
        var normalizedEmail = request.Email.Trim().ToUpperInvariant();

        var emailExists = await dbContext.Users
            .AnyAsync(u => u.Email.ToUpper() == normalizedEmail && u.DeletedAt == null, cancellationToken);

        if (emailExists)
        {
            throw new AuthException("Email is already registered.", 409);
        }

        var studentRole = await dbContext.Roles
            .FirstOrDefaultAsync(r => r.Code == RoleCodes.Student, cancellationToken)
            ?? throw new AuthException("Default student role is not configured.", 500);

        var userId = Guid.NewGuid();
        var displayName = string.IsNullOrWhiteSpace(request.DisplayName)
            ? request.Email.Split('@')[0]
            : request.DisplayName.Trim();

        var user = new User
        {
            UserId = userId,
            Email = request.Email.Trim(),
            DisplayName = displayName,
            AvatarId = "craft_01",
            PasswordHash = PasswordHasher.HashPassword(request.Password),
            Status = "active",
            CreatedAt = DateTime.UtcNow,
        };

        user.UserRoles.Add(new UserRole
        {
            UserId = userId,
            RoleId = studentRole.RoleId,
            CreatedAt = DateTime.UtcNow,
            Role = studentRole,
        });

        user.AuthProviders.Add(new AuthProvider
        {
            AuthProviderId = Guid.NewGuid(),
            UserId = userId,
            ProviderCode = "email",
            ProviderSubject = normalizedEmail,
            CreatedAt = DateTime.UtcNow,
        });

        dbContext.Users.Add(user);
        await dbContext.SaveChangesAsync(cancellationToken);
        await billingService.AssignFreePlanAsync(userId, cancellationToken);

        return BuildAuthResponse(user);
    }

    public async Task<AuthResponseDto> LoginAsync(
        LoginRequest request,
        CancellationToken cancellationToken = default)
    {
        var normalizedEmail = request.Email.Trim().ToUpperInvariant();

        var user = await dbContext.Users
            .Include(u => u.UserRoles)
            .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(
                u => u.Email.ToUpper() == normalizedEmail && u.DeletedAt == null,
                cancellationToken);

        if (user is null || user.PasswordHash is null || user.Status != "active")
        {
            throw new AuthException("Invalid email or password.", 401);
        }

        if (!PasswordHasher.VerifyPassword(request.Password, user.PasswordHash))
        {
            throw new AuthException("Invalid email or password.", 401);
        }

        return BuildAuthResponse(user);
    }

    public async Task<AuthTokensDto> RefreshAsync(
        RefreshTokenRequest request,
        CancellationToken cancellationToken = default)
    {
        var principal = jwtTokenService.ValidateToken(request.RefreshToken, "refresh")
            ?? throw new AuthException("Invalid refresh token.", 401);

        var userIdValue = principal.FindFirstValue(System.Security.Claims.ClaimTypes.NameIdentifier)
            ?? principal.FindFirstValue("sub");

        if (!Guid.TryParse(userIdValue, out var userId))
        {
            throw new AuthException("Invalid refresh token.", 401);
        }

        return await RefreshTokensForUserAsync(userId, cancellationToken);
    }

    public async Task<UserProfileDto> GetProfileAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var user = await dbContext.Users
            .Include(u => u.UserRoles)
            .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.UserId == userId && u.DeletedAt == null, cancellationToken)
            ?? throw new AuthException("User not found.", 404);

        return MapProfile(user);
    }

    public async Task<UserProfileDto> UpdateProfileAsync(
        Guid userId,
        UpdateProfileRequest request,
        CancellationToken cancellationToken = default)
    {
        var user = await dbContext.Users
            .Include(u => u.UserRoles)
            .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.UserId == userId && u.DeletedAt == null, cancellationToken)
            ?? throw new AuthException("User not found.", 404);

        if (request.DisplayName is not null)
        {
            var displayName = request.DisplayName.Trim();
            if (displayName.Length == 0 || displayName.Length > 160)
            {
                throw new AuthException(
                    "Invalid display name.",
                    400,
                    "INVALID_DISPLAY_NAME");
            }

            user.DisplayName = displayName;
        }

        if (request.AvatarId is not null)
        {
            if (!IsValidAvatarId(request.AvatarId))
            {
                throw new AuthException("Invalid avatar selection.");
            }

            user.AvatarId = request.AvatarId.Trim();
        }

        if (request.PreferredLanguage is not null)
        {
            var language = request.PreferredLanguage.Trim().ToLowerInvariant();
            if (!IsSupportedLanguage(language))
            {
                throw new AuthException("Unsupported language.");
            }

            user.PreferredLanguage = language;
        }

        user.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);

        return MapProfile(user);
    }

    public async Task ChangePasswordAsync(
        Guid userId,
        ChangePasswordRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.CurrentPassword)
            || string.IsNullOrWhiteSpace(request.NewPassword))
        {
            throw new AuthException("Current and new password are required.");
        }

        if (request.NewPassword.Length < 8)
        {
            throw new AuthException("New password must be at least 8 characters.");
        }

        var user = await dbContext.Users
            .FirstOrDefaultAsync(u => u.UserId == userId && u.DeletedAt == null, cancellationToken)
            ?? throw new AuthException("User not found.", 404);

        if (user.PasswordHash is null)
        {
            throw new AuthException("Password change is not available for this account.", 400);
        }

        if (!PasswordHasher.VerifyPassword(request.CurrentPassword, user.PasswordHash))
        {
            throw new AuthException("Current password is incorrect.", 401);
        }

        user.PasswordHash = PasswordHasher.HashPassword(request.NewPassword);
        user.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<AuthTokensDto> RefreshTokensForUserAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var user = await dbContext.Users
            .Include(u => u.UserRoles)
            .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.UserId == userId && u.DeletedAt == null, cancellationToken)
            ?? throw new AuthException("User not found.", 404);

        if (user.Status != "active")
        {
            throw new AuthException("User account is not active.", 403);
        }

        var roles = user.UserRoles.Select(ur => ur.Role.Code).ToList();
        return jwtTokenService.CreateTokenPair(user.UserId, user.Email, roles);
    }

    private AuthResponseDto BuildAuthResponse(User user)
    {
        var roles = user.UserRoles.Select(ur => ur.Role.Code).ToList();
        var tokens = jwtTokenService.CreateTokenPair(user.UserId, user.Email, roles);

        return new AuthResponseDto
        {
            Tokens = tokens,
            User = MapProfile(user),
        };
    }

    private static UserProfileDto MapProfile(User user) => new()
    {
        UserId = user.UserId,
        Email = user.Email,
        DisplayName = user.DisplayName,
        AvatarId = user.AvatarId ?? "craft_01",
        PreferredLanguage = user.PreferredLanguage,
        Roles = user.UserRoles.Select(ur => ur.Role.Code).ToList(),
    };

    private static bool IsSupportedLanguage(string language) =>
        language is "en" or "es" or "pt";

    private static bool IsValidAvatarId(string avatarId)
    {
        var normalized = avatarId.Trim();
        return normalized.Length is > 0 and <= 40
            && normalized.All(c => char.IsLetterOrDigit(c) || c == '_');
    }
}
