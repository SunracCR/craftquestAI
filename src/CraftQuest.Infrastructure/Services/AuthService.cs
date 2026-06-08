using System.Security.Claims;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Auth;
using CraftQuest.Application.Options;
using CraftQuest.Application.Services;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services;

public class AuthService(
    CraftQuestDbContext dbContext,
    JwtTokenService jwtTokenService,
    IBillingService billingService,
    IEmailSender emailSender,
    IGoogleIdTokenValidator googleIdTokenValidator,
    IAppleIdTokenValidator appleIdTokenValidator,
    IOptions<PasswordResetOptions> passwordResetOptions,
    IOptions<ExternalAuthOptions> externalAuthOptions) : IAuthService
{
    private readonly PasswordResetOptions _resetOptions = passwordResetOptions.Value;
    private readonly ExternalAuthOptions _externalAuth = externalAuthOptions.Value;

    public OAuthPublicConfigDto GetOAuthPublicConfig()
    {
        var googleId = _externalAuth.Google.WebClientId?.Trim();
        var appleBundle = _externalAuth.Apple.BundleId?.Trim();
        var appleServicesId = _externalAuth.Apple.ServicesId?.Trim();
        var appleWebRedirect = _externalAuth.Apple.WebRedirectUri?.Trim();

        return new OAuthPublicConfigDto
        {
            GoogleWebClientId = string.IsNullOrEmpty(googleId) ? null : googleId,
            IsGoogleConfigured = !string.IsNullOrEmpty(googleId),
            IsAppleConfigured = !string.IsNullOrEmpty(appleBundle)
                || !string.IsNullOrEmpty(appleServicesId),
            AppleServicesId = string.IsNullOrEmpty(appleServicesId) ? null : appleServicesId,
            AppleWebRedirectUri = string.IsNullOrEmpty(appleWebRedirect) ? null : appleWebRedirect,
            IsAppleWebConfigured = !string.IsNullOrEmpty(appleServicesId)
                && !string.IsNullOrEmpty(appleWebRedirect),
        };
    }
    public async Task<AuthResponseDto> RegisterAsync(
        RegisterRequest request,
        CancellationToken cancellationToken = default)
    {
        var normalizedEmail = request.Email.Trim().ToUpperInvariant();

        var emailExists = await dbContext.Users
            .AnyAsync(u => u.Email.ToUpper() == normalizedEmail, cancellationToken);

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
                u => u.Email.ToUpper() == normalizedEmail,
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

    public async Task<AuthResponseDto> LoginWithGoogleAsync(
        ExternalLoginRequest request,
        CancellationToken cancellationToken = default)
    {
        var identity = await googleIdTokenValidator.ValidateAsync(request.IdToken, cancellationToken);
        return await SignInWithExternalProviderAsync(
            "google",
            identity,
            request.Email,
            request.DisplayName,
            cancellationToken);
    }

    public async Task<AuthResponseDto> LoginWithAppleAsync(
        ExternalLoginRequest request,
        CancellationToken cancellationToken = default)
    {
        var identity = await appleIdTokenValidator.ValidateAsync(request.IdToken, cancellationToken);
        return await SignInWithExternalProviderAsync(
            "apple",
            identity,
            request.Email,
            request.DisplayName,
            cancellationToken);
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
            .FirstOrDefaultAsync(u => u.UserId == userId, cancellationToken)
            ?? throw new AuthException("User not found.", 404);

        return MapProfile(user);
    }

    public async Task<UserProfileDto> UpdateProfileAsync(
        Guid userId,
        UpdateProfileRequest request,
        CancellationToken cancellationToken = default)
    {
        var snapshot = await dbContext.Users
            .AsNoTracking()
            .Where(u => u.UserId == userId)
            .Select(u => new
            {
                u.UserId,
                u.Email,
                u.DisplayName,
                u.AvatarId,
                u.PreferredLanguage,
                Roles = u.UserRoles.Select(ur => ur.Role!.Code).ToList(),
            })
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new AuthException("User not found.", 404);

        var displayName = snapshot.DisplayName;
        var avatarId = snapshot.AvatarId;
        var preferredLanguage = snapshot.PreferredLanguage;
        var hasChanges = false;

        if (request.DisplayName is not null)
        {
            displayName = request.DisplayName.Trim();
            if (displayName.Length == 0 || displayName.Length > 160)
            {
                throw new AuthException(
                    "Invalid display name.",
                    400,
                    "INVALID_DISPLAY_NAME");
            }

            hasChanges = true;
        }

        if (request.AvatarId is not null)
        {
            if (!IsValidAvatarId(request.AvatarId))
            {
                throw new AuthException("Invalid avatar selection.");
            }

            avatarId = request.AvatarId.Trim();
            hasChanges = true;
        }

        if (request.PreferredLanguage is not null)
        {
            var language = request.PreferredLanguage.Trim().ToLowerInvariant();
            if (!IsSupportedLanguage(language))
            {
                throw new AuthException("Unsupported language.");
            }

            preferredLanguage = language;
            hasChanges = true;
        }

        if (hasChanges)
        {
            var updatedAt = DateTime.UtcNow;
            var rows = await dbContext.Users
                .Where(u => u.UserId == userId)
                .ExecuteUpdateAsync(
                    setters => setters
                        .SetProperty(u => u.DisplayName, displayName)
                        .SetProperty(u => u.AvatarId, avatarId)
                        .SetProperty(u => u.PreferredLanguage, preferredLanguage)
                        .SetProperty(u => u.UpdatedAt, updatedAt),
                    cancellationToken);

            if (rows == 0)
            {
                throw new AuthException("User not found.", 404);
            }
        }

        return new UserProfileDto
        {
            UserId = snapshot.UserId,
            Email = snapshot.Email,
            DisplayName = displayName,
            AvatarId = avatarId ?? "craft_01",
            PreferredLanguage = preferredLanguage,
            Roles = snapshot.Roles,
        };
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
            .FirstOrDefaultAsync(u => u.UserId == userId, cancellationToken)
            ?? throw new AuthException("User not found.", 404);

        if (user.PasswordHash is null)
        {
            throw new AuthException(
                "Password change is not available for this account.",
                400,
                "PASSWORD_CHANGE_UNAVAILABLE");
        }

        if (!PasswordHasher.VerifyPassword(request.CurrentPassword, user.PasswordHash))
        {
            throw new AuthException(
                "Current password is incorrect.",
                400,
                "CURRENT_PASSWORD_INCORRECT");
        }

        user.PasswordHash = PasswordHasher.HashPassword(request.NewPassword);
        user.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task RequestPasswordResetAsync(
        ForgotPasswordRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_resetOptions.Pepper))
        {
            throw new AuthException("Password reset is not configured.", 503, "PASSWORD_RESET_DISABLED");
        }

        var normalizedEmail = request.Email.Trim().ToUpperInvariant();
        var user = await dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(
                u => u.Email.ToUpper() == normalizedEmail
                   
                    && u.Status == "active"
                    && u.PasswordHash != null,
                cancellationToken);

        if (user is null)
        {
            return;
        }

        var rawToken = PasswordResetTokenHasher.GenerateToken();
        var tokenHash = PasswordResetTokenHasher.Hash(rawToken, _resetOptions.Pepper);
        var now = DateTime.UtcNow;

        var activeTokens = await dbContext.PasswordResetTokens
            .Where(t => t.UserId == user.UserId && t.UsedAt == null && t.ExpiresAt > now)
            .ToListAsync(cancellationToken);

        foreach (var existing in activeTokens)
        {
            existing.UsedAt = now;
        }

        dbContext.PasswordResetTokens.Add(new PasswordResetToken
        {
            PasswordResetTokenId = Guid.NewGuid(),
            UserId = user.UserId,
            TokenHash = tokenHash,
            ExpiresAt = now.AddMinutes(_resetOptions.TokenLifetimeMinutes),
            CreatedAt = now,
        });

        await dbContext.SaveChangesAsync(cancellationToken);

        var resetUrl = BuildResetUrl(rawToken);
        var language = user.PreferredLanguage ?? "es";
        var (subject, body) = BuildResetEmailContent(language, resetUrl, _resetOptions.TokenLifetimeMinutes);

        await emailSender.SendAsync(user.Email, subject, body, cancellationToken);
    }

    public async Task ResetPasswordAsync(
        ResetPasswordRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_resetOptions.Pepper))
        {
            throw new AuthException("Password reset is not configured.", 503, "PASSWORD_RESET_DISABLED");
        }

        if (request.NewPassword.Length < 8)
        {
            throw new AuthException("New password must be at least 8 characters.", 400);
        }

        var tokenHash = PasswordResetTokenHasher.Hash(request.Token.Trim(), _resetOptions.Pepper);
        var now = DateTime.UtcNow;

        var resetToken = await dbContext.PasswordResetTokens
            .Include(t => t.User)
            .FirstOrDefaultAsync(
                t => t.TokenHash == tokenHash && t.UsedAt == null && t.ExpiresAt > now,
                cancellationToken);

        if (resetToken is null || resetToken.User is null || resetToken.User.Status != "active")
        {
            throw new AuthException("Invalid or expired reset token.", 400, "INVALID_RESET_TOKEN");
        }

        resetToken.User.PasswordHash = PasswordHasher.HashPassword(request.NewPassword);
        resetToken.User.UpdatedAt = now;
        resetToken.UsedAt = now;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private string BuildResetUrl(string rawToken)
    {
        var baseUrl = _resetOptions.AppResetUrlBase.TrimEnd('/');
        return $"{baseUrl}?token={Uri.EscapeDataString(rawToken)}";
    }

    private static (string Subject, string Body) BuildResetEmailContent(
        string language,
        string resetUrl,
        int lifetimeMinutes)
    {
        return language switch
        {
            "en" => (
                "Reset your CraftQuest password",
                $"Use this link to choose a new password (valid for {lifetimeMinutes} minutes):\n\n{resetUrl}\n\nIf you did not request this, you can ignore this email."),
            "pt" => (
                "Redefinir sua senha CraftQuest",
                $"Use este link para escolher uma nova senha (valido por {lifetimeMinutes} minutos):\n\n{resetUrl}\n\nSe voce nao solicitou isso, ignore este e-mail."),
            _ => (
                "Restablecer tu contraseña de CraftQuest",
                $"Usa este enlace para elegir una nueva contraseña (válido {lifetimeMinutes} minutos):\n\n{resetUrl}\n\nSi no lo solicitaste, ignora este correo."),
        };
    }

    private async Task<AuthTokensDto> RefreshTokensForUserAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var user = await dbContext.Users
            .Include(u => u.UserRoles)
            .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.UserId == userId, cancellationToken)
            ?? throw new AuthException("User not found.", 404);

        if (user.Status != "active")
        {
            throw new AuthException("User account is not active.", 403);
        }

        var roles = user.UserRoles.Select(ur => ur.Role.Code).ToList();
        return jwtTokenService.CreateTokenPair(user.UserId, user.Email, roles);
    }

    private async Task<AuthResponseDto> SignInWithExternalProviderAsync(
        string providerCode,
        ExternalAuthUserInfo identity,
        string? clientEmail,
        string? clientDisplayName,
        CancellationToken cancellationToken)
    {
        var subject = identity.Subject.Trim();
        if (string.IsNullOrWhiteSpace(subject))
        {
            throw new AuthException("Invalid external identity.", 401);
        }

        var linked = await dbContext.AuthProviders
            .Include(ap => ap.User)
            .ThenInclude(u => u.UserRoles)
            .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(
                ap => ap.ProviderCode == providerCode && ap.ProviderSubject == subject,
                cancellationToken);

        if (linked?.User is { Status: "active" } activeUser)
        {
            return BuildAuthResponse(activeUser);
        }

        var email = ResolveExternalEmail(identity, clientEmail);
        if (string.IsNullOrWhiteSpace(email))
        {
            throw new AuthException(
                "Email is required for the first sign-in with this provider.",
                400,
                "EXTERNAL_EMAIL_REQUIRED");
        }

        email = email.Trim();
        var normalizedEmail = email.ToUpperInvariant();

        var userByEmail = await dbContext.Users
            .Include(u => u.UserRoles)
            .ThenInclude(ur => ur.Role)
            .Include(u => u.AuthProviders)
            .FirstOrDefaultAsync(
                u => u.Email.ToUpper() == normalizedEmail,
                cancellationToken);

        if (userByEmail is not null)
        {
            if (userByEmail.Status != "active")
            {
                throw new AuthException("User account is not active.", 403);
            }

            await EnsureAuthProviderLinkAsync(
                userByEmail,
                providerCode,
                subject,
                cancellationToken);
            return BuildAuthResponse(userByEmail);
        }

        var studentRole = await dbContext.Roles
            .FirstOrDefaultAsync(r => r.Code == RoleCodes.Student, cancellationToken)
            ?? throw new AuthException("Default student role is not configured.", 500);

        var userId = Guid.NewGuid();
        var displayName = ResolveExternalDisplayName(identity, clientDisplayName, email);

        var newUser = new User
        {
            UserId = userId,
            Email = email,
            DisplayName = displayName,
            AvatarId = "craft_01",
            PasswordHash = null,
            Status = "active",
            CreatedAt = DateTime.UtcNow,
        };

        newUser.UserRoles.Add(new UserRole
        {
            UserId = userId,
            RoleId = studentRole.RoleId,
            CreatedAt = DateTime.UtcNow,
            Role = studentRole,
        });

        newUser.AuthProviders.Add(new AuthProvider
        {
            AuthProviderId = Guid.NewGuid(),
            UserId = userId,
            ProviderCode = providerCode,
            ProviderSubject = subject,
            CreatedAt = DateTime.UtcNow,
        });

        dbContext.Users.Add(newUser);
        await dbContext.SaveChangesAsync(cancellationToken);
        await billingService.AssignFreePlanAsync(userId, cancellationToken);

        return BuildAuthResponse(newUser);
    }

    private async Task EnsureAuthProviderLinkAsync(
        User user,
        string providerCode,
        string subject,
        CancellationToken cancellationToken)
    {
        var alreadyLinked = user.AuthProviders.Any(
            ap => ap.ProviderCode == providerCode && ap.ProviderSubject == subject);

        if (alreadyLinked)
        {
            return;
        }

        var subjectTaken = await dbContext.AuthProviders.AnyAsync(
            ap => ap.ProviderCode == providerCode && ap.ProviderSubject == subject,
            cancellationToken);

        if (subjectTaken)
        {
            throw new AuthException(
                "This external account is already linked to another user.",
                409,
                "EXTERNAL_ACCOUNT_LINKED");
        }

        dbContext.AuthProviders.Add(new AuthProvider
        {
            AuthProviderId = Guid.NewGuid(),
            UserId = user.UserId,
            ProviderCode = providerCode,
            ProviderSubject = subject,
            CreatedAt = DateTime.UtcNow,
        });

        user.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private static string? ResolveExternalEmail(ExternalAuthUserInfo identity, string? clientEmail)
    {
        if (!string.IsNullOrWhiteSpace(identity.Email))
        {
            return identity.Email;
        }

        return string.IsNullOrWhiteSpace(clientEmail) ? null : clientEmail;
    }

    private static string ResolveExternalDisplayName(
        ExternalAuthUserInfo identity,
        string? clientDisplayName,
        string email)
    {
        if (!string.IsNullOrWhiteSpace(identity.DisplayName))
        {
            return identity.DisplayName.Trim();
        }

        if (!string.IsNullOrWhiteSpace(clientDisplayName))
        {
            return clientDisplayName.Trim();
        }

        return email.Split('@')[0];
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
