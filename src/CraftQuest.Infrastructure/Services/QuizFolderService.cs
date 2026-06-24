using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Quizzes;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class QuizFolderService(CraftQuestDbContext dbContext) : IQuizFolderService
{
    private const int MaxFolderDepth = 2;

    public async Task<IReadOnlyList<QuizFolderDto>> GetMyFoldersAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var folders = await dbContext.QuizFolders
            .AsNoTracking()
            .Where(f => f.OwnerUserId == userId)
            .OrderBy(f => f.ParentFolderId)
            .ThenBy(f => f.SortOrder)
            .ThenBy(f => f.Name)
            .Select(f => new
            {
                f.QuizFolderId,
                f.Name,
                f.ParentFolderId,
                f.Depth,
                f.SortOrder,
            })
            .ToListAsync(cancellationToken);

        var folderIds = folders.Select(f => f.QuizFolderId).ToList();
        var quizCounts = folderIds.Count == 0
            ? new Dictionary<Guid, int>()
            : await dbContext.Quizzes
                .AsNoTracking()
                .Where(q => q.CreatedByUserId == userId
                    && q.FolderId != null
                    && folderIds.Contains(q.FolderId.Value))
                .GroupBy(q => q.FolderId!.Value)
                .Select(g => new { FolderId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.FolderId, x => x.Count, cancellationToken);

        return folders
            .Select(f => new QuizFolderDto
            {
                QuizFolderId = f.QuizFolderId,
                Name = f.Name,
                ParentFolderId = f.ParentFolderId,
                Depth = f.Depth,
                SortOrder = f.SortOrder,
                QuizCount = quizCounts.GetValueOrDefault(f.QuizFolderId),
            })
            .ToList();
    }

    public async Task<QuizFolderDto> CreateFolderAsync(
        Guid userId,
        CreateQuizFolderRequest request,
        CancellationToken cancellationToken = default)
    {
        var name = request.Name.Trim();
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new AppException("Folder name is required.");
        }

        var parentDepth = await ResolveParentDepthAsync(
            userId,
            request.ParentFolderId,
            cancellationToken);

        var depth = parentDepth + 1;
        if (depth > MaxFolderDepth)
        {
            throw new AppException(
                "Maximum folder depth (3 levels) exceeded.",
                400,
                "QUIZ_FOLDER_MAX_DEPTH");
        }

        var sortOrder = await dbContext.QuizFolders
            .Where(f => f.OwnerUserId == userId && f.ParentFolderId == request.ParentFolderId)
            .MaxAsync(f => (int?)f.SortOrder, cancellationToken) ?? 0;

        var folder = new QuizFolder
        {
            QuizFolderId = Guid.NewGuid(),
            OwnerUserId = userId,
            Name = name,
            ParentFolderId = request.ParentFolderId,
            Depth = depth,
            SortOrder = sortOrder + 1,
            CreatedAt = DateTime.UtcNow,
        };

        dbContext.QuizFolders.Add(folder);
        await dbContext.SaveChangesAsync(cancellationToken);

        return MapFolder(folder, 0);
    }

    public async Task<QuizFolderDto> UpdateFolderAsync(
        Guid userId,
        Guid folderId,
        UpdateQuizFolderRequest request,
        CancellationToken cancellationToken = default)
    {
        var folder = await GetOwnedFolderAsync(userId, folderId, cancellationToken);
        var moveRequested = request.ClearParentFolder || request.ParentFolderId.HasValue;

        if (request.Name is not null)
        {
            var name = request.Name.Trim();
            if (string.IsNullOrWhiteSpace(name))
            {
                throw new AppException("Folder name is required.");
            }

            folder.Name = name;
        }

        if (moveRequested)
        {
            var newParentId = request.ClearParentFolder ? null : request.ParentFolderId;
            if (newParentId == folder.QuizFolderId)
            {
                throw new AppException("A folder cannot be moved into itself.");
            }

            if (newParentId is not null)
            {
                var descendantIds = await GetDescendantFolderIdsAsync(folderId, cancellationToken);
                if (descendantIds.Contains(newParentId.Value))
                {
                    throw new AppException("A folder cannot be moved into one of its subfolders.");
                }
            }

            var parentDepth = await ResolveParentDepthAsync(userId, newParentId, cancellationToken);
            var newDepth = parentDepth + 1;
            var subtreeMaxRelativeDepth = await GetSubtreeMaxRelativeDepthAsync(
                folderId,
                cancellationToken);

            if (newDepth + subtreeMaxRelativeDepth > MaxFolderDepth)
            {
                throw new AppException(
                    "Moving this folder would exceed the maximum depth of 3 levels.",
                    400,
                    "QUIZ_FOLDER_MAX_DEPTH");
            }

            folder.ParentFolderId = newParentId;
            folder.Depth = newDepth;
            await UpdateDescendantDepthsAsync(folderId, newDepth, cancellationToken);
        }

        folder.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);

        var quizCount = await dbContext.Quizzes
            .CountAsync(q => q.CreatedByUserId == userId && q.FolderId == folderId, cancellationToken);

        return MapFolder(folder, quizCount);
    }

    public async Task DeleteFolderAsync(
        Guid userId,
        Guid folderId,
        CancellationToken cancellationToken = default)
    {
        _ = await GetOwnedFolderAsync(userId, folderId, cancellationToken);

        var folderIds = await GetDescendantFolderIdsAsync(folderId, cancellationToken);
        folderIds.Add(folderId);

        var now = DateTime.UtcNow;
        var folders = await dbContext.QuizFolders
            .Where(f => folderIds.Contains(f.QuizFolderId) && f.OwnerUserId == userId)
            .ToListAsync(cancellationToken);

        foreach (var folder in folders)
        {
            folder.DeletedAt = now;
            folder.UpdatedAt = now;
        }

        var quizzes = await dbContext.Quizzes
            .Where(q => q.CreatedByUserId == userId
                && q.FolderId != null
                && folderIds.Contains(q.FolderId.Value))
            .ToListAsync(cancellationToken);

        foreach (var quiz in quizzes)
        {
            quiz.FolderId = null;
            quiz.UpdatedAt = now;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<int> ResolveParentDepthAsync(
        Guid userId,
        Guid? parentFolderId,
        CancellationToken cancellationToken)
    {
        if (parentFolderId is null)
        {
            return -1;
        }

        var parent = await dbContext.QuizFolders
            .AsNoTracking()
            .FirstOrDefaultAsync(
                f => f.QuizFolderId == parentFolderId && f.OwnerUserId == userId,
                cancellationToken)
            ?? throw new AppException("Parent folder not found.", 404);

        return parent.Depth;
    }

    private async Task<QuizFolder> GetOwnedFolderAsync(
        Guid userId,
        Guid folderId,
        CancellationToken cancellationToken)
    {
        var folder = await dbContext.QuizFolders
            .FirstOrDefaultAsync(
                f => f.QuizFolderId == folderId && f.OwnerUserId == userId,
                cancellationToken)
            ?? throw new AppException("Folder not found.", 404);

        return folder;
    }

    private async Task<List<Guid>> GetDescendantFolderIdsAsync(
        Guid folderId,
        CancellationToken cancellationToken)
    {
        var allFolders = await dbContext.QuizFolders
            .AsNoTracking()
            .Where(f => f.ParentFolderId != null)
            .Select(f => new { f.QuizFolderId, f.ParentFolderId })
            .ToListAsync(cancellationToken);

        var descendants = new List<Guid>();
        var queue = new Queue<Guid>();
        queue.Enqueue(folderId);

        while (queue.Count > 0)
        {
            var current = queue.Dequeue();
            foreach (var child in allFolders.Where(f => f.ParentFolderId == current))
            {
                descendants.Add(child.QuizFolderId);
                queue.Enqueue(child.QuizFolderId);
            }
        }

        return descendants;
    }

    private async Task<int> GetSubtreeMaxRelativeDepthAsync(
        Guid folderId,
        CancellationToken cancellationToken)
    {
        var allFolders = await dbContext.QuizFolders
            .AsNoTracking()
            .Select(f => new { f.QuizFolderId, f.ParentFolderId, f.Depth })
            .ToListAsync(cancellationToken);

        var root = allFolders.FirstOrDefault(f => f.QuizFolderId == folderId)
            ?? throw new AppException("Folder not found.", 404);

        var maxDepth = root.Depth;
        var queue = new Queue<Guid>();
        queue.Enqueue(folderId);

        while (queue.Count > 0)
        {
            var current = queue.Dequeue();
            foreach (var child in allFolders.Where(f => f.ParentFolderId == current))
            {
                maxDepth = Math.Max(maxDepth, child.Depth);
                queue.Enqueue(child.QuizFolderId);
            }
        }

        return maxDepth - root.Depth;
    }

    private async Task UpdateDescendantDepthsAsync(
        Guid folderId,
        int parentDepth,
        CancellationToken cancellationToken)
    {
        var allFolders = await dbContext.QuizFolders
            .Where(f => f.ParentFolderId != null)
            .ToListAsync(cancellationToken);

        var tracked = await dbContext.QuizFolders
            .Where(f => f.QuizFolderId == folderId)
            .ToListAsync(cancellationToken);

        var byId = tracked.ToDictionary(f => f.QuizFolderId);
        foreach (var folder in allFolders)
        {
            if (!byId.ContainsKey(folder.QuizFolderId))
            {
                byId[folder.QuizFolderId] = folder;
            }
        }

        var queue = new Queue<(Guid Id, int Depth)>();
        queue.Enqueue((folderId, parentDepth));

        while (queue.Count > 0)
        {
            var (currentId, currentDepth) = queue.Dequeue();
            foreach (var child in allFolders.Where(f => f.ParentFolderId == currentId))
            {
                var childDepth = currentDepth + 1;
                if (byId.TryGetValue(child.QuizFolderId, out var entity))
                {
                    entity.Depth = childDepth;
                    entity.UpdatedAt = DateTime.UtcNow;
                }

                queue.Enqueue((child.QuizFolderId, childDepth));
            }
        }
    }

    private static QuizFolderDto MapFolder(QuizFolder folder, int quizCount) => new()
    {
        QuizFolderId = folder.QuizFolderId,
        Name = folder.Name,
        ParentFolderId = folder.ParentFolderId,
        Depth = folder.Depth,
        SortOrder = folder.SortOrder,
        QuizCount = quizCount,
    };
}
