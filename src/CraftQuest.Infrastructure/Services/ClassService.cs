using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Teacher;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.Quizzes;
using CraftQuest.Infrastructure.Services.Teacher;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class ClassService(
    CraftQuestDbContext dbContext) : IClassService
{
    public async Task<IReadOnlyList<TeacherClassSummaryDto>> ListTeacherClassesAsync(
        Guid teacherUserId,
        string? status = "active",
        CancellationToken cancellationToken = default)
    {
        var query = dbContext.TeacherClasses
            .AsNoTracking()
            .Where(c => c.TeacherUserId == teacherUserId);

        query = query.Where(c => c.Status != "deleted");

        if (!string.Equals(status, "all", StringComparison.OrdinalIgnoreCase))
        {
            var filterStatus = string.IsNullOrWhiteSpace(status) ? "active" : status.Trim().ToLowerInvariant();
            query = query.Where(c => c.Status == filterStatus);
        }

        var classes = await query
            .OrderBy(c => c.Status == "active" ? 0 : 1)
            .ThenBy(c => c.Name)
            .Select(c => new
            {
                c.ClassId,
                c.Name,
                c.Description,
                c.Status,
                ActiveMemberCount = c.Members.Count(m => m.Status == "active"),
                PendingMemberCount = c.Members.Count(m => m.Status == "pending"),
            })
            .ToListAsync(cancellationToken);

        if (classes.Count == 0)
        {
            return [];
        }

        var classIds = classes.Select(c => c.ClassId).ToList();
        var assignmentCounts = await dbContext.Assignments
            .AsNoTracking()
            .Where(a => classIds.Contains(a.ClassId) && a.Status != "archived")
            .GroupBy(a => a.ClassId)
            .Select(g => new { ClassId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.ClassId, x => x.Count, cancellationToken);

        return classes
            .Select(c => new TeacherClassSummaryDto
            {
                ClassId = c.ClassId,
                Name = c.Name,
                Description = c.Description,
                Status = c.Status,
                ActiveMemberCount = c.ActiveMemberCount,
                PendingMemberCount = c.PendingMemberCount,
                AssignmentCount = assignmentCounts.GetValueOrDefault(c.ClassId),
            })
            .ToList();
    }

    public async Task<TeacherClassSummaryDto> CreateAsync(
        Guid teacherUserId,
        CreateClassRequest request,
        CancellationToken cancellationToken = default)
    {
        var name = request.Name.Trim();
        if (string.IsNullOrEmpty(name))
            throw new AppException("Class name is required.", 400);

        var entity = new TeacherClass
        {
            ClassId = Guid.NewGuid(),
            TeacherUserId = teacherUserId,
            Name = name,
            Description = request.Description?.Trim(),
            Status = "active",
            CreatedAt = DateTime.UtcNow,
        };

        dbContext.TeacherClasses.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);

        return new TeacherClassSummaryDto
        {
            ClassId = entity.ClassId,
            Name = entity.Name,
            Description = entity.Description,
            Status = entity.Status,
            ActiveMemberCount = 0,
            PendingMemberCount = 0,
            AssignmentCount = 0,
        };
    }

    public async Task UpdateAsync(
        Guid teacherUserId,
        Guid classId,
        UpdateClassRequest request,
        CancellationToken cancellationToken = default)
    {
        var entity = await LoadOwnedClassAsync(teacherUserId, classId, cancellationToken);
        entity.Name = request.Name.Trim();
        entity.Description = request.Description?.Trim();
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task ArchiveAsync(
        Guid teacherUserId,
        Guid classId,
        CancellationToken cancellationToken = default)
    {
        var entity = await LoadOwnedClassAsync(teacherUserId, classId, cancellationToken);
        if (entity.Status == "archived")
        {
            return;
        }

        entity.Status = "archived";
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task RestoreAsync(
        Guid teacherUserId,
        Guid classId,
        CancellationToken cancellationToken = default)
    {
        var entity = await LoadOwnedClassAsync(teacherUserId, classId, cancellationToken);
        if (entity.Status != "archived")
        {
            throw new AppException(
                "Class is not archived.",
                400,
                "CLASS_NOT_ARCHIVED");
        }

        entity.Status = "active";
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task DeleteAsync(
        Guid teacherUserId,
        Guid classId,
        CancellationToken cancellationToken = default)
    {
        var entity = await LoadOwnedClassAsync(teacherUserId, classId, cancellationToken);
        if (entity.Status != "archived")
        {
            throw new AppException(
                "Only archived classes can be deleted. Archive the class first.",
                400,
                "CLASS_MUST_BE_ARCHIVED");
        }

        if (entity.Status == "deleted")
        {
            return;
        }

        entity.Status = "deleted";
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<ClassDetailDto> GetDetailAsync(
        Guid teacherUserId,
        Guid classId,
        CancellationToken cancellationToken = default)
    {
        await EnsureTeacherOwnsClassForReadAsync(teacherUserId, classId, cancellationToken);

        var entity = await dbContext.TeacherClasses
            .AsNoTracking()
            .Include(c => c.Members)
                .ThenInclude(m => m.User)
            .FirstAsync(c => c.ClassId == classId, cancellationToken);

        var assignments = await dbContext.Assignments
            .AsNoTracking()
            .Where(a => a.ClassId == classId && a.Status != "archived")
            .OrderByDescending(a => a.CreatedAt)
            .ToListAsync(cancellationToken);

        var quizTitles = await QuizTitleLookup.LoadTitlesAsync(
            dbContext,
            assignments.Select(a => a.QuizId),
            cancellationToken);

        var memberCount = entity.Members.Count(m => m.Status == "active");

        var completedByAssignment = await AssignmentCompletionLookup.LoadUniqueCompletedCountsAsync(
            dbContext,
            assignments.Select(a => a.AssignmentId),
            cancellationToken);

        var assignmentSummaries = new List<AssignmentSummaryDto>(assignments.Count);
        foreach (var a in assignments)
        {
            completedByAssignment.TryGetValue(a.AssignmentId, out var completed);

            assignmentSummaries.Add(new AssignmentSummaryDto
            {
                AssignmentId = a.AssignmentId,
                ClassId = a.ClassId,
                QuizId = a.QuizId,
                Title = a.Title,
                QuizTitle = QuizTitleLookup.Resolve(quizTitles, a.QuizId, a.Title),
                Status = a.Status,
                ShowCorrectAnswersMode = a.ShowCorrectAnswersMode,
                StartsAt = a.StartsAt,
                DueAt = a.DueAt,
                MaxAttempts = a.MaxAttempts,
                RandomizeQuestions = a.RandomizeQuestions,
                AllowStudentRandomizeQuestions = a.AllowStudentRandomizeQuestions,
                ForfeitExitCountsAsAttempt = a.ForfeitExitCountsAsAttempt,
                CompletedCount = completed,
                TotalMembers = memberCount,
                CreatedAt = a.CreatedAt,
            });
        }

        var members = entity.Members
            .OrderBy(m => m.Status == "active" ? 0 : m.Status == "pending" ? 1 : 2)
            .ThenBy(m => m.User.DisplayName ?? m.User.Email)
            .Select(m => new ClassMemberDto
            {
                UserId = m.UserId,
                DisplayName = m.User.DisplayName ?? m.User.Email,
                Email = m.User.Email,
                MemberRole = m.MemberRole,
                Status = m.Status,
                JoinedAt = m.JoinedAt,
                AvatarId = m.User.AvatarId,
            })
            .ToList();

        return new ClassDetailDto
        {
            ClassId = entity.ClassId,
            Name = entity.Name,
            Description = entity.Description,
            Status = entity.Status,
            ActiveMemberCount = entity.Members.Count(m => m.Status == "active"),
            PendingMemberCount = entity.Members.Count(m => m.Status == "pending"),
            Members = members,
            Assignments = assignmentSummaries,
        };
    }

    public async Task AddMemberByEmailAsync(
        Guid teacherUserId,
        Guid classId,
        string email,
        CancellationToken cancellationToken = default)
    {
        await EnsureTeacherOwnsClassAsync(teacherUserId, classId, cancellationToken);

        var trimmedEmail = email.Trim();
        if (string.IsNullOrWhiteSpace(trimmedEmail) || !IsValidEmail(trimmedEmail))
        {
            throw new AppException("Invalid email address.", 400, "INVALID_EMAIL");
        }

        var normalizedEmail = trimmedEmail.ToUpperInvariant();
        var user = await dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.EmailNormalized == normalizedEmail, cancellationToken)
            ?? throw new AppException(
                "No user found with that email address.",
                404,
                "USER_NOT_FOUND");

        var existing = await dbContext.ClassMembers
            .FirstOrDefaultAsync(m => m.ClassId == classId && m.UserId == user.UserId, cancellationToken);

        if (existing is not null)
        {
            if (existing.Status == "active")
                throw new AppException(
                    "This user is already a member of the class.",
                    409,
                    "CLASS_MEMBER_ALREADY_EXISTS");

            existing.Status = "active";
            existing.JoinedAt = DateTime.UtcNow;
            await dbContext.SaveChangesAsync(cancellationToken);
            return;
        }

        dbContext.ClassMembers.Add(new ClassMember
        {
            ClassMemberId = Guid.NewGuid(),
            ClassId = classId,
            UserId = user.UserId,
            MemberRole = "student",
            Status = "active",
            JoinedAt = DateTime.UtcNow,
        });

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task ApproveMemberAsync(
        Guid teacherUserId,
        Guid classId,
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        await EnsureTeacherOwnsClassAsync(teacherUserId, classId, cancellationToken);

        var member = await dbContext.ClassMembers
            .FirstOrDefaultAsync(m => m.ClassId == classId && m.UserId == userId, cancellationToken)
            ?? throw new AppException("Member not found in this class.", 404);

        member.Status = "active";
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task RemoveMemberAsync(
        Guid teacherUserId,
        Guid classId,
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        await EnsureTeacherOwnsClassAsync(teacherUserId, classId, cancellationToken);

        var member = await dbContext.ClassMembers
            .FirstOrDefaultAsync(m => m.ClassId == classId && m.UserId == userId, cancellationToken)
            ?? throw new AppException("Member not found in this class.", 404);

        member.Status = "removed";
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public Task<bool> IsActiveClassMemberAsync(
        Guid userId,
        Guid classId,
        CancellationToken cancellationToken = default) =>
        dbContext.ClassMembers.AnyAsync(
            m => m.ClassId == classId && m.UserId == userId && m.Status == "active",
            cancellationToken);

    public async Task EnsureTeacherOwnsClassAsync(
        Guid teacherUserId,
        Guid classId,
        CancellationToken cancellationToken = default)
    {
        var owns = await dbContext.TeacherClasses.AnyAsync(
            c => c.ClassId == classId
                && c.TeacherUserId == teacherUserId
                && c.Status == "active",
            cancellationToken);

        if (!owns)
            throw new AppException("Class not found or you do not own it.", 404);
    }

    private async Task EnsureTeacherOwnsClassForReadAsync(
        Guid teacherUserId,
        Guid classId,
        CancellationToken cancellationToken)
    {
        var owns = await dbContext.TeacherClasses.AnyAsync(
            c => c.ClassId == classId
                && c.TeacherUserId == teacherUserId
                && c.Status != "deleted",
            cancellationToken);

        if (!owns)
            throw new AppException("Class not found or you do not own it.", 404);
    }

    private async Task<TeacherClass> LoadOwnedClassAsync(
        Guid teacherUserId,
        Guid classId,
        CancellationToken cancellationToken)
    {
        var entity = await dbContext.TeacherClasses
            .FirstOrDefaultAsync(
                c => c.ClassId == classId && c.TeacherUserId == teacherUserId,
                cancellationToken)
            ?? throw new AppException("Class not found or you do not own it.", 404);
        return entity;
    }

    private static bool IsValidEmail(string email)
    {
        try
        {
            var trimmed = email.Trim();
            var addr = new System.Net.Mail.MailAddress(trimmed);
            return string.Equals(addr.Address, trimmed, StringComparison.OrdinalIgnoreCase);
        }
        catch
        {
            return false;
        }
    }
}
