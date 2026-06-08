using System.Security.Cryptography;
using CraftQuest.Application.Constants;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Sharing;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class ShareCodeService(
    CraftQuestDbContext dbContext,
    IBillingService billingService,
    IClassService classService) : IShareCodeService
{
    private static readonly HashSet<string> ValidCodeTypes =
        ["single_use", "class_capacity", "purchased_key"];

    private static readonly HashSet<string> ValidAccessPolicies =
        ["guest_open", "registered_open", "group_only", "direct_user"];

    public async Task<ShareCodeDto?> GetQuizShareCodeAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        await EnsureQuizOwnerForSharingAsync(userId, quizId, cancellationToken);

        var entity = await dbContext.ShareCodes
            .AsNoTracking()
            .FirstOrDefaultAsync(
                s => s.QuizId == quizId && s.AssignmentId == null && s.Status != "revoked",
                cancellationToken);

        return entity is null ? null : MapShareCode(entity);
    }

    public async Task<ShareCodeDto> CreateShareCodeAsync(
        Guid userId,
        Guid quizId,
        CreateShareCodeRequest request,
        CancellationToken cancellationToken = default)
    {
        var quiz = await EnsureQuizOwnerForSharingAsync(userId, quizId, cancellationToken);

        var isTeacher = await IsTeacherAsync(userId, cancellationToken);
        var (accessPolicy, classId) = await ResolveShareSettingsAsync(
            userId,
            isTeacher,
            request,
            cancellationToken);

        var codeType = string.IsNullOrWhiteSpace(request.CodeType)
            ? ShareCodeDefaults.MultiUseCodeType
            : request.CodeType.Trim().ToLowerInvariant();

        if (!ValidCodeTypes.Contains(codeType))
        {
            throw new AppException("Invalid share code type.");
        }

        if (codeType == "single_use")
        {
            throw new AppException(
                "Use multi-use sharing. Single-use codes are not supported for quiz sharing.",
                400);
        }

        var existing = await dbContext.ShareCodes
            .FirstOrDefaultAsync(
                s => s.QuizId == quizId && s.AssignmentId == null,
                cancellationToken);

        if (existing is not null)
        {
            existing.AccessPolicy = accessPolicy;
            existing.ClassId = classId;
            existing.ExpiresAt = request.ExpiresAt ?? existing.ExpiresAt;
            if (existing.Status is "exhausted" or "expired")
            {
                existing.Status = "active";
            }

            await dbContext.SaveChangesAsync(cancellationToken);
            return MapShareCode(existing, isExisting: true);
        }

        var entity = new ShareCode
        {
            ShareCodeId = Guid.NewGuid(),
            Code = await GenerateUniqueCodeAsync(cancellationToken),
            QuizId = quizId,
            ClassId = classId,
            CreatedByUserId = userId,
            CodeType = codeType,
            MaxRedemptions = int.MaxValue,
            ExpiresAt = request.ExpiresAt,
            Status = "active",
            AccessPolicy = accessPolicy,
            CreatedAt = DateTime.UtcNow,
        };

        dbContext.ShareCodes.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);

        return MapShareCode(entity, isExisting: false);
    }

    public async Task<RedeemShareCodeResultDto> RedeemAsync(
        Guid userId,
        RedeemShareCodeRequest request,
        CancellationToken cancellationToken = default)
    {
        var normalizedCode = request.Code.Trim().ToUpperInvariant();
        if (string.IsNullOrWhiteSpace(normalizedCode))
        {
            throw new AppException("Share code is required.", 400);
        }

        var shareCode = await dbContext.ShareCodes
            .Include(s => s.Quiz)
            .FirstOrDefaultAsync(
                s => s.Code == normalizedCode,
                cancellationToken)
            ?? throw new AppException("Share code not found.", 404);

        ValidateShareCodeActive(shareCode);
        await ValidateRegisteredAccessAsync(shareCode, userId, cancellationToken);

        if (shareCode.QuizId is null || shareCode.Quiz is null)
        {
            throw new AppException("Share code is not linked to a valid quiz.", 400);
        }

        if (shareCode.Quiz.PublicationStatus != "published")
        {
            throw new AppException("This quiz is not available for practice.", 403);
        }

        if (shareCode.Quiz.CreatedByUserId == userId)
        {
            throw new AppException(
                "You cannot redeem a share code for a quiz you created.",
                400,
                "CANNOT_REDEEM_OWN_QUIZ");
        }

        var quizId = shareCode.QuizId.Value;
        var accessClassId = shareCode.AccessPolicy == "group_only" ? shareCode.ClassId : null;

        var alreadyInSharedList = await dbContext.QuizAccesses.AnyAsync(
            a => a.UserId == userId
                && a.QuizId == quizId
                && a.AssignmentId == null
                && a.AccessType == "redeemed",
            cancellationToken);

        if (alreadyInSharedList)
        {
            return new RedeemShareCodeResultDto
            {
                QuizId = quizId,
                ClassId = shareCode.ClassId,
                AssignmentId = shareCode.AssignmentId,
                QuizTitle = shareCode.Quiz.Title,
                AlreadyInSharedList = true,
            };
        }

        await billingService.EnsureCanRedeemSharedQuizAsync(userId, quizId, cancellationToken);

        dbContext.QuizAccesses.Add(new QuizAccess
        {
            QuizAccessId = Guid.NewGuid(),
            UserId = userId,
            QuizId = quizId,
            ClassId = accessClassId,
            AccessType = "redeemed",
            GrantedByShareCodeId = shareCode.ShareCodeId,
            GrantedAt = DateTime.UtcNow,
        });

        await dbContext.SaveChangesAsync(cancellationToken);

        return new RedeemShareCodeResultDto
        {
            QuizId = quizId,
            ClassId = shareCode.ClassId,
            AssignmentId = shareCode.AssignmentId,
            QuizTitle = shareCode.Quiz.Title,
            AlreadyInSharedList = false,
        };
    }

    public async Task<IReadOnlyList<AccessibleQuizDto>> GetAccessibleQuizzesAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var accesses = await dbContext.QuizAccesses
            .AsNoTracking()
            .Where(a => a.UserId == userId
                && a.AssignmentId == null
                && a.AccessType == "redeemed")
            .Include(a => a.Quiz)
            .Where(a => a.Quiz.PublicationStatus == "published")
            .OrderByDescending(a => a.GrantedAt)
            .ToListAsync(cancellationToken);

        var quizIds = accesses.Select(a => a.QuizId).ToList();
        var ownerIds = accesses.Select(a => a.Quiz.CreatedByUserId).Distinct().ToList();
        var owners = await dbContext.Users
            .AsNoTracking()
            .Where(u => ownerIds.Contains(u.UserId))
            .ToDictionaryAsync(
                u => u.UserId,
                u => u.DisplayName ?? u.Email,
                cancellationToken);

        var questionCounts = await dbContext.Questions
            .Where(q => quizIds.Contains(q.QuizId))
            .GroupBy(q => q.QuizId)
            .Select(g => new { QuizId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.QuizId, x => x.Count, cancellationToken);

        return accesses
            .Select(a => new AccessibleQuizDto
            {
                QuizId = a.QuizId,
                Title = a.Quiz.Title,
                Description = a.Quiz.Description,
                PublicationStatus = a.Quiz.PublicationStatus,
                QuestionCount = questionCounts.GetValueOrDefault(a.QuizId),
                AccessType = a.AccessType,
                SharedByUserId = a.Quiz.CreatedByUserId,
                SharedByDisplayName = owners.GetValueOrDefault(a.Quiz.CreatedByUserId),
            })
            .ToList();
    }

    public async Task RemoveAccessibleQuizAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        var quiz = await dbContext.Quizzes
            .AsNoTracking()
            .FirstOrDefaultAsync(q => q.QuizId == quizId, cancellationToken)
            ?? throw new AppException("Quiz not found.", 404);

        if (quiz.CreatedByUserId == userId)
        {
            throw new AppException(
                "Use quiz delete to remove quizzes you created.",
                400,
                "ACCESS_REMOVE_NOT_APPLICABLE");
        }

        var accesses = await dbContext.QuizAccesses
            .Where(a => a.UserId == userId
                && a.QuizId == quizId
                && a.AssignmentId == null
                && a.AccessType == "redeemed")
            .ToListAsync(cancellationToken);

        if (accesses.Count == 0)
        {
            throw new AppException(
                "Shared quiz access not found.",
                404,
                "SHARED_QUIZ_ACCESS_NOT_FOUND");
        }

        dbContext.QuizAccesses.RemoveRange(accesses);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private const int MaxInviteEmailsPerRequest = 20;

    public async Task<InviteUsersResultDto> InviteUsersByEmailAsync(
        Guid ownerId,
        Guid quizId,
        InviteUsersRequest request,
        CancellationToken cancellationToken = default)
    {
        await EnsureQuizOwnerForSharingAsync(ownerId, quizId, cancellationToken);
        await billingService.EnsureCanInviteUserToQuizAsync(ownerId, cancellationToken);

        var rawEmails = request.Emails ?? [];
        if (rawEmails.Count == 0)
        {
            throw new AppException("At least one email is required.", 400, "INVALID_EMAIL");
        }

        if (rawEmails.Count > MaxInviteEmailsPerRequest)
        {
            throw new AppException(
                $"You can invite up to {MaxInviteEmailsPerRequest} users at a time.",
                400,
                "INVITE_BATCH_TOO_LARGE");
        }

        var distinctEmails = rawEmails
            .Select(e => e.Trim())
            .Where(e => !string.IsNullOrWhiteSpace(e))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (distinctEmails.Count == 0)
        {
            throw new AppException("At least one email is required.", 400, "INVALID_EMAIL");
        }

        var shareCodeId = await dbContext.ShareCodes
            .AsNoTracking()
            .Where(s => s.QuizId == quizId && s.AssignmentId == null && s.Status != "revoked")
            .Select(s => (Guid?)s.ShareCodeId)
            .FirstOrDefaultAsync(cancellationToken);

        var results = new List<InviteUserResultItemDto>();
        foreach (var email in distinctEmails)
        {
            results.Add(await InviteSingleUserAsync(
                ownerId,
                quizId,
                email,
                shareCodeId,
                cancellationToken));
        }

        if (results.Any(r => r.Outcome is "invited" or "already_had_access"))
        {
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        return new InviteUsersResultDto { Results = results };
    }

    public async Task<bool> HasQuizAccessAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        var quiz = await dbContext.Quizzes
            .AsNoTracking()
            .FirstOrDefaultAsync(q => q.QuizId == quizId, cancellationToken);

        if (quiz is null)
        {
            return false;
        }

        if (quiz.CreatedByUserId == userId)
        {
            return true;
        }

        if (quiz.Visibility == "public")
        {
            return true;
        }

        var now = DateTime.UtcNow;

        if (await dbContext.QuizAccesses.AnyAsync(
                a => a.UserId == userId
                    && a.QuizId == quizId
                    && a.AssignmentId == null
                    && a.ClassId == null
                    && a.AccessType == "redeemed",
                cancellationToken))
        {
            return true;
        }

        if (await dbContext.QuizAccesses.AnyAsync(
                a => a.UserId == userId
                    && a.QuizId == quizId
                    && a.AccessType == "purchase"
                    && a.ExpiresAt != null
                    && a.ExpiresAt > now,
                cancellationToken))
        {
            return true;
        }

        return false;
    }

    private async Task<InviteUserResultItemDto> InviteSingleUserAsync(
        Guid ownerId,
        Guid quizId,
        string email,
        Guid? shareCodeId,
        CancellationToken cancellationToken)
    {
        if (!IsValidEmail(email))
        {
            return new InviteUserResultItemDto
            {
                Email = email,
                Outcome = "invalid_email",
            };
        }

        var normalizedEmail = email.ToUpperInvariant();
        var user = await dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(
                u => u.Email.ToUpper() == normalizedEmail,
                cancellationToken);

        if (user is null)
        {
            return new InviteUserResultItemDto
            {
                Email = email,
                Outcome = "not_found",
            };
        }

        if (user.UserId == ownerId)
        {
            return new InviteUserResultItemDto
            {
                Email = email,
                Outcome = "self",
                DisplayName = user.DisplayName ?? user.Email,
            };
        }

        var alreadyHasAccess = await dbContext.QuizAccesses.AnyAsync(
            a => a.UserId == user.UserId
                && a.QuizId == quizId
                && a.AssignmentId == null
                && a.AccessType == "redeemed",
            cancellationToken);

        if (alreadyHasAccess)
        {
            return new InviteUserResultItemDto
            {
                Email = email,
                Outcome = "already_had_access",
                DisplayName = user.DisplayName ?? user.Email,
            };
        }

        try
        {
            await billingService.EnsureCanRedeemSharedQuizAsync(
                user.UserId,
                quizId,
                cancellationToken);
        }
        catch (AppException ex) when (ex.ErrorCode == "SHARED_QUIZ_SLOT_LIMIT")
        {
            return new InviteUserResultItemDto
            {
                Email = email,
                Outcome = "slot_limit",
                DisplayName = user.DisplayName ?? user.Email,
            };
        }

        dbContext.QuizAccesses.Add(new QuizAccess
        {
            QuizAccessId = Guid.NewGuid(),
            UserId = user.UserId,
            QuizId = quizId,
            AccessType = "redeemed",
            GrantedByShareCodeId = shareCodeId,
            GrantedAt = DateTime.UtcNow,
        });

        return new InviteUserResultItemDto
        {
            Email = email,
            Outcome = "invited",
            DisplayName = user.DisplayName ?? user.Email,
        };
    }

    private static bool IsValidEmail(string email)
    {
        try
        {
            var trimmed = email.Trim();
            var addr = new System.Net.Mail.MailAddress(trimmed);
            return addr.Address.Equals(trimmed, StringComparison.OrdinalIgnoreCase);
        }
        catch
        {
            return false;
        }
    }

    private async Task<Quiz> EnsureQuizOwnerForSharingAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken)
    {
        var quiz = await dbContext.Quizzes
            .FirstOrDefaultAsync(q => q.QuizId == quizId, cancellationToken)
            ?? throw new AppException("Quiz not found.", 404);

        if (quiz.CreatedByUserId != userId)
        {
            throw new AppException("You do not have permission to share this quiz.", 403);
        }

        if (quiz.PublicationStatus != "published")
        {
            throw new AppException("Publish the quiz before creating share codes.", 400);
        }

        return quiz;
    }

    private static void ValidateShareCodeActive(ShareCode shareCode)
    {
        if (shareCode.Status == "revoked")
        {
            throw new AppException("Share code has been revoked.", 400);
        }

        if (shareCode.ExpiresAt.HasValue && shareCode.ExpiresAt.Value < DateTime.UtcNow)
        {
            throw new AppException("Share code has expired.", 400);
        }
    }

    private async Task<string> GenerateUniqueCodeAsync(CancellationToken cancellationToken)
    {
        for (var attempt = 0; attempt < 10; attempt++)
        {
            var suffix = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
            var code = $"CQ-{suffix}";
            var exists = await dbContext.ShareCodes
                .AnyAsync(s => s.Code == code, cancellationToken);
            if (!exists)
            {
                return code;
            }
        }

        throw new AppException("Could not generate a unique share code.", 500);
    }

    private async Task<bool> IsTeacherAsync(Guid userId, CancellationToken cancellationToken) =>
        await dbContext.UserRoles
            .AsNoTracking()
            .AnyAsync(
                ur => ur.UserId == userId && ur.Role.Code == RoleCodes.Teacher,
                cancellationToken);

    private async Task<(string AccessPolicy, Guid? ClassId)> ResolveShareSettingsAsync(
        Guid userId,
        bool isTeacher,
        CreateShareCodeRequest request,
        CancellationToken cancellationToken)
    {
        if (!isTeacher)
        {
            return ("guest_open", null);
        }

        var accessPolicy = (request.AccessPolicy ?? "guest_open").Trim().ToLowerInvariant();
        if (!ValidAccessPolicies.Contains(accessPolicy))
        {
            throw new AppException("Invalid access policy.");
        }

        if (accessPolicy is "registered_open" or "direct_user")
        {
            throw new AppException(
                "Teachers must choose open-to-anyone (guest_open) or group-only (group_only).",
                400);
        }

        if (accessPolicy == "group_only")
        {
            if (request.ClassId is null || request.ClassId == Guid.Empty)
            {
                throw new AppException("ClassId is required for group-only share codes.", 400);
            }

            await classService.EnsureTeacherOwnsClassAsync(
                userId,
                request.ClassId.Value,
                cancellationToken);

            return (accessPolicy, request.ClassId);
        }

        return ("guest_open", null);
    }

    private async Task ValidateRegisteredAccessAsync(
        ShareCode shareCode,
        Guid userId,
        CancellationToken cancellationToken)
    {
        switch (shareCode.AccessPolicy)
        {
            case "guest_open":
            case "registered_open":
                return;
            case "group_only":
                if (shareCode.ClassId is null)
                {
                    throw new AppException("Share code is not linked to a class.", 400);
                }

                if (!await classService.IsActiveClassMemberAsync(
                        userId,
                        shareCode.ClassId.Value,
                        cancellationToken))
                {
                    var className = await GetClassNameAsync(
                        shareCode.ClassId.Value,
                        cancellationToken);

                    throw new AppException(
                        "This code is only for members of the teacher's class.",
                        403,
                        errorCode: "GROUP_ACCESS_DENIED",
                        metadata: BuildGroupAccessDeniedMetadata(className));
                }

                return;
            case "direct_user":
                throw new AppException(
                    "This code must be assigned directly by the teacher.",
                    403,
                    errorCode: "DIRECT_USER_ONLY");
            default:
                throw new AppException("Invalid share code access policy.", 400);
        }
    }

    private async Task<string?> GetClassNameAsync(
        Guid classId,
        CancellationToken cancellationToken) =>
        await dbContext.TeacherClasses
            .AsNoTracking()
            .Where(c => c.ClassId == classId)
            .Select(c => c.Name)
            .FirstOrDefaultAsync(cancellationToken);

    private static Dictionary<string, object?> BuildGroupAccessDeniedMetadata(string? className)
    {
        var metadata = new Dictionary<string, object?>();
        if (!string.IsNullOrWhiteSpace(className))
        {
            metadata["className"] = className.Trim();
        }

        return metadata;
    }

    private static ShareCodeDto MapShareCode(ShareCode entity, bool isExisting = false) => new()
    {
        ShareCodeId = entity.ShareCodeId,
        Code = entity.Code,
        QuizId = entity.QuizId!.Value,
        CodeType = entity.CodeType,
        MaxRedemptions = entity.MaxRedemptions,
        RedemptionsCount = entity.RedemptionsCount,
        Status = entity.Status,
        AccessPolicy = entity.AccessPolicy,
        ClassId = entity.ClassId,
        ExpiresAt = entity.ExpiresAt,
        IsExisting = isExisting,
    };
}
