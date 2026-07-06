using System.Security.Claims;
using CraftQuest.Application;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Auth;
using CraftQuest.Application.Options;
using CraftQuest.Application.Services;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Email;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
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
    IOptions<JoinLinkOptions> joinLinkOptions,
    IOptions<ExternalAuthOptions> externalAuthOptions,
    ILogger<AuthService> logger) : IAuthService
{
    private const int MinimumAgeWithoutParentalConsent = 13;

    private readonly PasswordResetOptions _resetOptions = passwordResetOptions.Value;
    private readonly JoinLinkOptions _joinLinkOptions = joinLinkOptions.Value;
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

    public async Task<RegisterResultDto> RegisterAsync(
        RegisterRequest request,
        CancellationToken cancellationToken = default)
    {
        EnsureTokenSecurityConfigured();

        var normalizedEmail = request.Email.Trim().ToUpperInvariant();

        var emailExists = await dbContext.Users
            .AnyAsync(u => u.EmailNormalized == normalizedEmail, cancellationToken);

        if (emailExists)
        {
            throw new AuthException("Email is already registered.", 409);
        }

        var studentRole = await dbContext.Roles
            .FirstOrDefaultAsync(r => r.Code == RoleCodes.Student, cancellationToken)
            ?? throw new AuthException("Default student role is not configured.", 500);

        var requiresParentalConsent = false;
        string? guardianEmail = null;
        if (request.DateOfBirth.HasValue)
        {
            var age = CalculateAge(request.DateOfBirth.Value);
            if (age < MinimumAgeWithoutParentalConsent)
            {
                if (string.IsNullOrWhiteSpace(request.GuardianEmail))
                {
                    throw new AuthException(
                        "Guardian email is required for users under 13.",
                        400,
                        "GUARDIAN_EMAIL_REQUIRED");
                }

                requiresParentalConsent = true;
                guardianEmail = request.GuardianEmail.Trim();
            }
        }

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
            Status = UserStatuses.Pending,
            DateOfBirth = request.DateOfBirth,
            ParentalConsentStatus = requiresParentalConsent
                ? ParentalConsentStatuses.Pending
                : ParentalConsentStatuses.NotRequired,
            GuardianEmail = guardianEmail,
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

        await SendVerificationEmailAsync(user, cancellationToken);

        if (requiresParentalConsent)
        {
            await SendParentalConsentEmailAsync(user, cancellationToken);
        }

        return new RegisterResultDto
        {
            RequiresEmailVerification = true,
            RequiresParentalConsent = requiresParentalConsent,
            Email = user.Email,
            GuardianEmail = guardianEmail,
        };
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
                u => u.EmailNormalized == normalizedEmail,
                cancellationToken);

        if (user is null || user.PasswordHash is null)
        {
            throw new AuthException("Invalid email or password.", 401);
        }

        if (user.Status == UserStatuses.Pending)
        {
            throw new AuthException(
                "Email address is not verified.",
                403,
                "EMAIL_NOT_VERIFIED");
        }

        if (user.Status == UserStatuses.PendingParentalConsent)
        {
            throw new AuthException(
                "Waiting for parental consent.",
                403,
                "PARENTAL_CONSENT_PENDING");
        }

        if (user.Status != UserStatuses.Active)
        {
            throw new AuthException("Invalid email or password.", 401);
        }

        if (!PasswordHasher.VerifyPassword(request.Password, user.PasswordHash))
        {
            throw new AuthException("Invalid email or password.", 401);
        }

        return BuildAuthResponse(user);
    }

    public async Task<AuthResponseDto> VerifyEmailAsync(
        VerifyEmailRequest request,
        CancellationToken cancellationToken = default)
    {
        EnsureTokenSecurityConfigured();

        if (string.IsNullOrWhiteSpace(request.Token))
        {
            throw new AuthException("Verification token is required.", 400);
        }

        var tokenHash = PasswordResetTokenHasher.Hash(request.Token.Trim(), _resetOptions.Pepper);
        var now = DateTime.UtcNow;

        var verificationToken = await dbContext.EmailVerificationTokens
            .Include(t => t.User)
            .ThenInclude(u => u.UserRoles)
            .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(
                t => t.TokenHash == tokenHash && t.UsedAt == null && t.ExpiresAt > now,
                cancellationToken);

        if (verificationToken?.User is null || verificationToken.User.Status != UserStatuses.Pending)
        {
            throw new AuthException("Invalid or expired verification token.", 400, "INVALID_VERIFICATION_TOKEN");
        }

        verificationToken.User.EmailVerifiedAt = now;
        verificationToken.User.UpdatedAt = now;
        verificationToken.UsedAt = now;

        if (verificationToken.User.ParentalConsentStatus == ParentalConsentStatuses.Pending)
        {
            verificationToken.User.Status = UserStatuses.PendingParentalConsent;
        }
        else
        {
            verificationToken.User.Status = UserStatuses.Active;
            await billingService.AssignFreePlanAsync(verificationToken.User.UserId, cancellationToken);
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        if (verificationToken.User.Status == UserStatuses.Active)
        {
            return BuildAuthResponse(verificationToken.User);
        }

        throw new AuthException(
            "Waiting for parental consent.",
            403,
            "PARENTAL_CONSENT_PENDING");
    }

    public async Task ResendVerificationAsync(
        ResendVerificationRequest request,
        CancellationToken cancellationToken = default)
    {
        EnsureTokenSecurityConfigured();

        var normalizedEmail = request.Email.Trim().ToUpperInvariant();
        var user = await dbContext.Users
            .FirstOrDefaultAsync(
                u => u.EmailNormalized == normalizedEmail && u.Status == "pending",
                cancellationToken);

        if (user is null)
        {
            return;
        }

        await SendVerificationEmailAsync(user, cancellationToken);
    }

    public async Task DeleteAccountAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var user = await dbContext.Users
            .FirstOrDefaultAsync(u => u.UserId == userId, cancellationToken)
            ?? throw new AuthException("User not found.", 404);

        if (user.Status == "deleted" || user.DeletedAt is not null)
        {
            throw new AuthException("User account is already deleted.", 404);
        }

        var deviceTokens = await dbContext.DeviceTokens
            .Where(t => t.UserId == userId)
            .ToListAsync(cancellationToken);
        dbContext.DeviceTokens.RemoveRange(deviceTokens);

        var emailTokens = await dbContext.EmailVerificationTokens
            .Where(t => t.UserId == userId)
            .ToListAsync(cancellationToken);
        dbContext.EmailVerificationTokens.RemoveRange(emailTokens);

        var resetTokens = await dbContext.PasswordResetTokens
            .Where(t => t.UserId == userId)
            .ToListAsync(cancellationToken);
        dbContext.PasswordResetTokens.RemoveRange(resetTokens);

        var changeTokens = await dbContext.PasswordChangeTokens
            .Where(t => t.UserId == userId)
            .ToListAsync(cancellationToken);
        dbContext.PasswordChangeTokens.RemoveRange(changeTokens);

        var parentalTokens = await dbContext.ParentalConsentTokens
            .Where(t => t.UserId == userId)
            .ToListAsync(cancellationToken);
        dbContext.ParentalConsentTokens.RemoveRange(parentalTokens);

        var now = DateTime.UtcNow;
        user.Status = UserStatuses.Deleted;
        user.DeletedAt = now;
        user.UpdatedAt = now;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<AuthResponseDto> ConfirmParentalConsentAsync(
        ConfirmParentalConsentRequest request,
        CancellationToken cancellationToken = default)
    {
        EnsureTokenSecurityConfigured();

        if (string.IsNullOrWhiteSpace(request.Token))
        {
            throw new AuthException("Consent token is required.", 400);
        }

        var tokenHash = PasswordResetTokenHasher.Hash(request.Token.Trim(), _resetOptions.Pepper);
        var now = DateTime.UtcNow;

        var consentToken = await dbContext.ParentalConsentTokens
            .Include(t => t.User)
            .ThenInclude(u => u.UserRoles)
            .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(
                t => t.TokenHash == tokenHash && t.UsedAt == null && t.ExpiresAt > now,
                cancellationToken);

        if (consentToken?.User is null
            || consentToken.User.ParentalConsentStatus != ParentalConsentStatuses.Pending)
        {
            throw new AuthException(
                "Invalid or expired parental consent token.",
                400,
                "INVALID_PARENTAL_CONSENT_TOKEN");
        }

        consentToken.User.ParentalConsentStatus = ParentalConsentStatuses.Granted;
        consentToken.User.ParentalConsentAt = now;
        consentToken.User.UpdatedAt = now;
        consentToken.UsedAt = now;

        if (consentToken.User.EmailVerifiedAt is not null)
        {
            consentToken.User.Status = UserStatuses.Active;
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        if (consentToken.User.Status == UserStatuses.Active)
        {
            await billingService.AssignFreePlanAsync(consentToken.User.UserId, cancellationToken);
            return BuildAuthResponse(consentToken.User);
        }

        throw new AuthException(
            "Email address is not verified.",
            403,
            "EMAIL_NOT_VERIFIED");
    }

    public async Task ResendParentalConsentAsync(
        ResendParentalConsentRequest request,
        CancellationToken cancellationToken = default)
    {
        EnsureTokenSecurityConfigured();

        var normalizedEmail = request.Email.Trim().ToUpperInvariant();
        var user = await dbContext.Users
            .FirstOrDefaultAsync(
                u => u.EmailNormalized == normalizedEmail
                    && u.Status == UserStatuses.PendingParentalConsent
                    && u.ParentalConsentStatus == ParentalConsentStatuses.Pending,
                cancellationToken);

        if (user is null || string.IsNullOrWhiteSpace(user.GuardianEmail))
        {
            return;
        }

        await SendParentalConsentEmailAsync(user, cancellationToken);
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

        var userIdValue = principal.FindFirstValue(ClaimTypes.NameIdentifier)
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
                u.DateOfBirth,
                Roles = u.UserRoles.Select(ur => ur.Role!.Code).ToList(),
            })
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new AuthException("User not found.", 404);

        var displayName = snapshot.DisplayName;
        var avatarId = snapshot.AvatarId;
        var preferredLanguage = snapshot.PreferredLanguage;
        var dateOfBirth = snapshot.DateOfBirth;
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

        if (request.DateOfBirth.HasValue)
        {
            var dob = request.DateOfBirth.Value;
            if (dob > DateOnly.FromDateTime(DateTime.UtcNow))
            {
                throw new AuthException("Invalid date of birth.", 400, "INVALID_DATE_OF_BIRTH");
            }

            dateOfBirth = dob;
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
                        .SetProperty(u => u.DateOfBirth, dateOfBirth)
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
            DateOfBirth = dateOfBirth,
            Roles = snapshot.Roles,
        };
    }

    public async Task<ChangePasswordResultDto> ChangePasswordAsync(
        Guid userId,
        ChangePasswordRequest request,
        CancellationToken cancellationToken = default)
    {
        EnsureTokenSecurityConfigured();

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

        var rawToken = PasswordResetTokenHasher.GenerateToken();
        var tokenHash = PasswordResetTokenHasher.Hash(rawToken, _resetOptions.Pepper);
        var now = DateTime.UtcNow;
        var newPasswordHash = PasswordHasher.HashPassword(request.NewPassword);

        var activeTokens = await dbContext.PasswordChangeTokens
            .Where(t => t.UserId == userId && t.UsedAt == null && t.ExpiresAt > now)
            .ToListAsync(cancellationToken);

        foreach (var existing in activeTokens)
        {
            existing.UsedAt = now;
        }

        dbContext.PasswordChangeTokens.Add(new PasswordChangeToken
        {
            PasswordChangeTokenId = Guid.NewGuid(),
            UserId = userId,
            TokenHash = tokenHash,
            NewPasswordHash = newPasswordHash,
            ExpiresAt = now.AddMinutes(_resetOptions.TokenLifetimeMinutes),
            CreatedAt = now,
        });

        await dbContext.SaveChangesAsync(cancellationToken);

        var actionUrl = AccountLinkUrlBuilder.BuildLandingUrl(
            _joinLinkOptions,
            AccountLinkUrlBuilder.ConfirmPasswordChange,
            rawToken);
        var language = user.PreferredLanguage ?? "es";
        var (subject, plainText, html) = EmailTemplateBuilder.BuildConfirmPasswordChange(
            language,
            actionUrl,
            _resetOptions.TokenLifetimeMinutes);

        await emailSender.SendAsync(user.Email, subject, plainText, html, cancellationToken);

        return new ChangePasswordResultDto { RequiresEmailConfirmation = true };
    }

    public async Task ConfirmPasswordChangeAsync(
        ConfirmPasswordChangeRequest request,
        CancellationToken cancellationToken = default)
    {
        EnsureTokenSecurityConfigured();

        if (string.IsNullOrWhiteSpace(request.Token))
        {
            throw new AuthException("Confirmation token is required.", 400);
        }

        var tokenHash = PasswordResetTokenHasher.Hash(request.Token.Trim(), _resetOptions.Pepper);
        var now = DateTime.UtcNow;

        var changeToken = await dbContext.PasswordChangeTokens
            .Include(t => t.User)
            .FirstOrDefaultAsync(
                t => t.TokenHash == tokenHash && t.UsedAt == null && t.ExpiresAt > now,
                cancellationToken);

        if (changeToken?.User is null || changeToken.User.Status != "active")
        {
            throw new AuthException("Invalid or expired confirmation token.", 400, "INVALID_PASSWORD_CHANGE_TOKEN");
        }

        changeToken.User.PasswordHash = changeToken.NewPasswordHash;
        changeToken.User.UpdatedAt = now;
        changeToken.UsedAt = now;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task RequestPasswordResetAsync(
        ForgotPasswordRequest request,
        CancellationToken cancellationToken = default)
    {
        EnsureTokenSecurityConfigured();

        var normalizedEmail = request.Email.Trim().ToUpperInvariant();
        var user = await dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(
                u => u.EmailNormalized == normalizedEmail
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

        var resetUrl = AccountLinkUrlBuilder.BuildLandingUrl(
            _joinLinkOptions,
            AccountLinkUrlBuilder.ResetPassword,
            rawToken);
        var language = user.PreferredLanguage ?? "es";
        var (subject, plainText, html) = EmailTemplateBuilder.BuildPasswordReset(
            language,
            resetUrl,
            _resetOptions.TokenLifetimeMinutes);

        await emailSender.SendAsync(user.Email, subject, plainText, html, cancellationToken);
    }

    public async Task ResetPasswordAsync(
        ResetPasswordRequest request,
        CancellationToken cancellationToken = default)
    {
        EnsureTokenSecurityConfigured();

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

    private async Task SendVerificationEmailAsync(User user, CancellationToken cancellationToken)
    {
        var rawToken = PasswordResetTokenHasher.GenerateToken();
        var tokenHash = PasswordResetTokenHasher.Hash(rawToken, _resetOptions.Pepper);
        var now = DateTime.UtcNow;

        var activeTokens = await dbContext.EmailVerificationTokens
            .Where(t => t.UserId == user.UserId && t.UsedAt == null && t.ExpiresAt > now)
            .ToListAsync(cancellationToken);

        foreach (var existing in activeTokens)
        {
            existing.UsedAt = now;
        }

        dbContext.EmailVerificationTokens.Add(new EmailVerificationToken
        {
            EmailVerificationTokenId = Guid.NewGuid(),
            UserId = user.UserId,
            TokenHash = tokenHash,
            ExpiresAt = now.AddMinutes(_resetOptions.TokenLifetimeMinutes),
            CreatedAt = now,
        });

        await dbContext.SaveChangesAsync(cancellationToken);

        var actionUrl = AccountLinkUrlBuilder.BuildLandingUrl(
            _joinLinkOptions,
            AccountLinkUrlBuilder.VerifyEmail,
            rawToken);
        var language = user.PreferredLanguage ?? "es";
        var (subject, plainText, html) = EmailTemplateBuilder.BuildVerifyEmail(
            language,
            actionUrl,
            _resetOptions.TokenLifetimeMinutes);

        await emailSender.SendAsync(user.Email, subject, plainText, html, cancellationToken);
    }

    private async Task SendParentalConsentEmailAsync(User user, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(user.GuardianEmail))
        {
            return;
        }

        var rawToken = PasswordResetTokenHasher.GenerateToken();
        var tokenHash = PasswordResetTokenHasher.Hash(rawToken, _resetOptions.Pepper);
        var now = DateTime.UtcNow;

        var activeTokens = await dbContext.ParentalConsentTokens
            .Where(t => t.UserId == user.UserId && t.UsedAt == null && t.ExpiresAt > now)
            .ToListAsync(cancellationToken);

        foreach (var existing in activeTokens)
        {
            existing.UsedAt = now;
        }

        dbContext.ParentalConsentTokens.Add(new ParentalConsentToken
        {
            ParentalConsentTokenId = Guid.NewGuid(),
            UserId = user.UserId,
            TokenHash = tokenHash,
            ExpiresAt = now.AddMinutes(_resetOptions.TokenLifetimeMinutes),
            CreatedAt = now,
        });

        await dbContext.SaveChangesAsync(cancellationToken);

        var actionUrl = AccountLinkUrlBuilder.BuildLandingUrl(
            _joinLinkOptions,
            AccountLinkUrlBuilder.ParentalConsent,
            rawToken);
        var language = user.PreferredLanguage ?? "es";
        var displayName = user.DisplayName ?? user.Email;
        var (subject, plainText, html) = EmailTemplateBuilder.BuildParentalConsent(
            language,
            displayName,
            actionUrl,
            _resetOptions.TokenLifetimeMinutes);

        await emailSender.SendAsync(
            user.GuardianEmail,
            subject,
            plainText,
            html,
            cancellationToken);
    }

    private static int CalculateAge(DateOnly dateOfBirth)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var age = today.Year - dateOfBirth.Year;
        if (dateOfBirth > today.AddYears(-age))
        {
            age--;
        }

        return age;
    }

    private void EnsureTokenSecurityConfigured()
    {
        if (string.IsNullOrWhiteSpace(_resetOptions.Pepper))
        {
            throw new AuthException("Email token security is not configured.", 503, "EMAIL_TOKENS_DISABLED");
        }
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

        if (user.Status != UserStatuses.Active)
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
                u => u.EmailNormalized == normalizedEmail,
                cancellationToken);

        if (userByEmail is not null)
        {
            if (userByEmail.Status == "pending")
            {
                throw new AuthException(
                    "Email address is not verified.",
                    403,
                    "EMAIL_NOT_VERIFIED");
            }

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
        var now = DateTime.UtcNow;

        var newUser = new User
        {
            UserId = userId,
            Email = email,
            DisplayName = displayName,
            AvatarId = "craft_01",
            PasswordHash = null,
            Status = "active",
            EmailVerifiedAt = now,
            CreatedAt = now,
        };

        newUser.UserRoles.Add(new UserRole
        {
            UserId = userId,
            RoleId = studentRole.RoleId,
            CreatedAt = now,
            Role = studentRole,
        });

        newUser.AuthProviders.Add(new AuthProvider
        {
            AuthProviderId = Guid.NewGuid(),
            UserId = userId,
            ProviderCode = providerCode,
            ProviderSubject = subject,
            CreatedAt = now,
        });

        dbContext.Users.Add(newUser);
        try
        {
            await dbContext.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException ex) when (IsDuplicateUserEmailConstraint(ex))
        {
            dbContext.Entry(newUser).State = EntityState.Detached;

            var racedUser = await dbContext.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .Include(u => u.AuthProviders)
                .FirstOrDefaultAsync(
                    u => u.EmailNormalized == normalizedEmail,
                    cancellationToken);

            if (racedUser is null)
            {
                throw;
            }

            if (racedUser.Status == "pending")
            {
                throw new AuthException(
                    "Email address is not verified.",
                    403,
                    "EMAIL_NOT_VERIFIED");
            }

            if (racedUser.Status != "active")
            {
                throw new AuthException("User account is not active.", 403);
            }

            await EnsureAuthProviderLinkAsync(
                racedUser,
                providerCode,
                subject,
                cancellationToken);
            return BuildAuthResponse(racedUser);
        }

        try
        {
            await billingService.AssignFreePlanAsync(userId, cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogError(
                ex,
                "Failed to assign free plan after external sign-in for user {UserId}",
                userId);
        }

        return BuildAuthResponse(newUser);
    }

    private static bool IsDuplicateUserEmailConstraint(DbUpdateException ex)
    {
        var message = ex.InnerException?.Message ?? ex.Message;
        return message.Contains("UQ_Users_EmailNormalized", StringComparison.OrdinalIgnoreCase)
            || (message.Contains("duplicate key", StringComparison.OrdinalIgnoreCase)
                && message.Contains("Users", StringComparison.OrdinalIgnoreCase));
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
        DateOfBirth = user.DateOfBirth,
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
