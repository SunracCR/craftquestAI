using System.Text.Json;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Notifications;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Email;
using CraftQuest.Infrastructure.Notifications;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace CraftQuest.Infrastructure.Services;

public class NotificationService(
    CraftQuestDbContext dbContext,
    IEmailSender emailSender,
    IServiceScopeFactory scopeFactory,
    ILogger<NotificationService> logger) : INotificationService
{
    private sealed record PushDelivery(
        Guid UserId,
        string Title,
        string Body,
        IReadOnlyDictionary<string, string>? Data);

    private sealed record EmailDelivery(
        string Email,
        string Language,
        string Type,
        NotificationPayload Payload);
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true,
    };

    private static readonly HashSet<string> EmailEligibleTypes =
    [
        NotificationTypes.QuizShared,
        NotificationTypes.ClassJoined,
        NotificationTypes.AssignmentCreated,
        NotificationTypes.AssignmentDueSoon,
        NotificationTypes.AiJobCompleted,
        NotificationTypes.AiJobFailed,
        NotificationTypes.MembershipExpiring,
        NotificationTypes.MembershipExpired,
    ];

    public async Task NotifyAsync(
        Guid userId,
        string type,
        NotificationPayload payload,
        string? dedupKey = null,
        CancellationToken cancellationToken = default)
    {
        await NotifyManyAsync(
            [userId],
            type,
            payload,
            dedupKey is null ? null : _ => dedupKey,
            cancellationToken);
    }

    public async Task NotifyManyAsync(
        IReadOnlyList<Guid> userIds,
        string type,
        NotificationPayload payload,
        Func<Guid, string?>? dedupKeyFactory = null,
        CancellationToken cancellationToken = default)
    {
        if (userIds.Count == 0)
        {
            return;
        }

        var distinctUserIds = userIds.Distinct().ToList();
        var languages = await dbContext.Users
            .AsNoTracking()
            .Where(u => distinctUserIds.Contains(u.UserId))
            .Select(u => new { u.UserId, u.PreferredLanguage, u.Email })
            .ToDictionaryAsync(u => u.UserId, cancellationToken);

        var preferences = await LoadPreferencesMapAsync(distinctUserIds, type, cancellationToken);
        var existingDedupKeys = await LoadExistingDedupKeysAsync(
            distinctUserIds,
            dedupKeyFactory,
            cancellationToken);
        var now = DateTime.UtcNow;
        var entities = new List<Notification>();
        var pushDeliveries = new List<PushDelivery>();
        var emailDeliveries = new List<EmailDelivery>();

        foreach (var userId in distinctUserIds)
        {
            if (!languages.TryGetValue(userId, out var user))
            {
                continue;
            }

            var pref = preferences.GetValueOrDefault(userId);
            var inAppEnabled = ResolvePreference(pref?.InAppEnabled, defaultValue: true);
            var pushEnabled = ResolvePreference(pref?.PushEnabled, defaultValue: true);
            var emailEnabled = ResolvePreference(
                pref?.EmailEnabled,
                GetDefaultEmailEnabled(type));
            if (!inAppEnabled && !pushEnabled &&
                (!EmailEligibleTypes.Contains(type) || !emailEnabled))
            {
                continue;
            }

            var dedupKey = dedupKeyFactory?.Invoke(userId);
            if (dedupKey is not null && existingDedupKeys.Contains((userId, dedupKey)))
            {
                continue;
            }

            var (title, body) = NotificationTextBuilder.Build(
                type,
                user.PreferredLanguage ?? "es",
                payload);

            if (inAppEnabled)
            {
                entities.Add(new Notification
                {
                    NotificationId = Guid.NewGuid(),
                    UserId = userId,
                    Type = type,
                    Title = title,
                    Body = body,
                    DataJson = JsonSerializer.Serialize(payload, JsonOptions),
                    IsRead = false,
                    CreatedAt = now,
                    DedupKey = dedupKey,
                });
            }

            if (pushEnabled)
            {
                pushDeliveries.Add(new PushDelivery(
                    userId,
                    title,
                    body,
                    BuildPushData(type, payload)));
            }

            if (emailEnabled && EmailEligibleTypes.Contains(type))
            {
                emailDeliveries.Add(new EmailDelivery(
                    user.Email,
                    user.PreferredLanguage ?? "es",
                    type,
                    payload));
            }
        }

        if (entities.Count > 0)
        {
            dbContext.Notifications.AddRange(entities);
            try
            {
                await dbContext.SaveChangesAsync(cancellationToken);
            }
            catch (DbUpdateException ex) when (dedupKeyFactory is not null)
            {
                logger.LogDebug(ex, "Skipped duplicate notifications for type {Type}", type);
            }
        }

        QueuePushDeliveriesInBackground(pushDeliveries);
        await SendEmailDeliveriesAsync(emailDeliveries, cancellationToken);
    }

    private async Task SendEmailDeliveriesAsync(
        IReadOnlyList<EmailDelivery> emailDeliveries,
        CancellationToken cancellationToken)
    {
        foreach (var email in emailDeliveries)
        {
            try
            {
                await SendNotificationEmailAsync(
                    emailSender,
                    email.Email,
                    email.Language,
                    email.Type,
                    email.Payload,
                    cancellationToken);
            }
            catch (Exception ex)
            {
                logger.LogWarning(
                    ex,
                    "Email failed for {Email}, type {Type}",
                    email.Email,
                    email.Type);
            }
        }
    }

    private async Task<HashSet<(Guid UserId, string DedupKey)>> LoadExistingDedupKeysAsync(
        IReadOnlyList<Guid> userIds,
        Func<Guid, string?>? dedupKeyFactory,
        CancellationToken cancellationToken)
    {
        if (dedupKeyFactory is null)
        {
            return [];
        }

        var pairs = userIds
            .Select(userId => (UserId: userId, Key: dedupKeyFactory(userId)))
            .Where(pair => pair.Key is not null)
            .ToList();

        if (pairs.Count == 0)
        {
            return [];
        }

        var dedupKeys = pairs.Select(pair => pair.Key!).Distinct().ToList();
        var existing = await dbContext.Notifications
            .AsNoTracking()
            .Where(n => userIds.Contains(n.UserId)
                && n.DedupKey != null
                && dedupKeys.Contains(n.DedupKey))
            .Select(n => new { n.UserId, n.DedupKey })
            .ToListAsync(cancellationToken);

        return existing
            .Select(row => (row.UserId, row.DedupKey!))
            .ToHashSet();
    }

    private void QueuePushDeliveriesInBackground(IReadOnlyList<PushDelivery> pushDeliveries)
    {
        if (pushDeliveries.Count == 0)
        {
            return;
        }

        _ = Task.Run(async () =>
        {
            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var scopedPush = scope.ServiceProvider.GetRequiredService<IPushSender>();

                foreach (var push in pushDeliveries)
                {
                    try
                    {
                        await scopedPush.SendAsync(
                            push.UserId,
                            push.Title,
                            push.Body,
                            push.Data,
                            CancellationToken.None);
                    }
                    catch (Exception ex)
                    {
                        logger.LogWarning(
                            ex,
                            "Push failed for user {UserId}",
                            push.UserId);
                    }
                }
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Background push delivery failed");
            }
        });
    }

    public async Task EnqueueFanOutAsync(
        string eventType,
        string payloadJson,
        CancellationToken cancellationToken = default)
    {
        dbContext.NotificationOutbox.Add(new NotificationOutbox
        {
            NotificationOutboxId = Guid.NewGuid(),
            EventType = eventType,
            PayloadJson = payloadJson,
            Status = "pending",
            CreatedAt = DateTime.UtcNow,
        });
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<NotificationListResultDto> ListAsync(
        Guid userId,
        string? cursor,
        int limit,
        bool unreadOnly,
        CancellationToken cancellationToken = default)
    {
        limit = Math.Clamp(limit, 1, 50);
        DateTime? cursorCreatedAt = null;
        Guid? cursorId = null;
        if (!string.IsNullOrWhiteSpace(cursor))
        {
            var parts = cursor.Split('|');
            if (parts.Length == 2
                && DateTime.TryParse(parts[0], null, System.Globalization.DateTimeStyles.RoundtripKind, out var parsedDate)
                && Guid.TryParse(parts[1], out var parsedId))
            {
                cursorCreatedAt = parsedDate;
                cursorId = parsedId;
            }
        }

        var query = dbContext.Notifications
            .AsNoTracking()
            .Where(n => n.UserId == userId);

        if (unreadOnly)
        {
            query = query.Where(n => !n.IsRead);
        }

        if (cursorCreatedAt is not null && cursorId is not null)
        {
            query = query.Where(n =>
                n.CreatedAt < cursorCreatedAt
                || (n.CreatedAt == cursorCreatedAt && n.NotificationId.CompareTo(cursorId.Value) < 0));
        }

        var items = await query
            .OrderByDescending(n => n.CreatedAt)
            .ThenByDescending(n => n.NotificationId)
            .Take(limit + 1)
            .ToListAsync(cancellationToken);

        string? nextCursor = null;
        if (items.Count > limit)
        {
            var last = items[limit - 1];
            nextCursor = $"{last.CreatedAt:O}|{last.NotificationId}";
            items = items.Take(limit).ToList();
        }

        var unreadCount = await CountUnreadAsync(userId, cancellationToken);

        return new NotificationListResultDto
        {
            Items = items.Select(Map).ToList(),
            NextCursor = nextCursor,
            UnreadCount = unreadCount,
        };
    }

    public Task<int> CountUnreadAsync(
        Guid userId,
        CancellationToken cancellationToken = default) =>
        dbContext.Notifications.CountAsync(
            n => n.UserId == userId && !n.IsRead,
            cancellationToken);

    public async Task MarkReadAsync(
        Guid userId,
        Guid notificationId,
        CancellationToken cancellationToken = default)
    {
        var entity = await dbContext.Notifications
            .FirstOrDefaultAsync(
                n => n.NotificationId == notificationId && n.UserId == userId,
                cancellationToken)
            ?? throw new AppException("Notification not found.", 404);

        if (!entity.IsRead)
        {
            entity.IsRead = true;
            entity.ReadAt = DateTime.UtcNow;
            await dbContext.SaveChangesAsync(cancellationToken);
        }
    }

    public async Task MarkAllReadAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        await dbContext.Notifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .ExecuteUpdateAsync(
                s => s
                    .SetProperty(n => n.IsRead, true)
                    .SetProperty(n => n.ReadAt, now),
                cancellationToken);
    }

    public async Task RegisterDeviceTokenAsync(
        Guid userId,
        RegisterDeviceTokenRequest request,
        CancellationToken cancellationToken = default)
    {
        var token = request.Token.Trim();
        if (string.IsNullOrWhiteSpace(token))
        {
            throw new AppException("Device token is required.", 400);
        }

        var platform = request.Platform.Trim().ToLowerInvariant();
        if (platform is not ("android" or "ios" or "web"))
        {
            throw new AppException("Invalid platform.", 400);
        }

        var now = DateTime.UtcNow;
        var existing = await dbContext.DeviceTokens
            .FirstOrDefaultAsync(t => t.Token == token, cancellationToken);

        if (existing is not null)
        {
            existing.UserId = userId;
            existing.Platform = platform;
            existing.LastSeenAt = now;
        }
        else
        {
            dbContext.DeviceTokens.Add(new DeviceToken
            {
                DeviceTokenId = Guid.NewGuid(),
                UserId = userId,
                Token = token,
                Platform = platform,
                CreatedAt = now,
                LastSeenAt = now,
            });
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task RemoveDeviceTokenAsync(
        Guid userId,
        string token,
        CancellationToken cancellationToken = default)
    {
        var trimmed = token.Trim();
        var entity = await dbContext.DeviceTokens
            .FirstOrDefaultAsync(t => t.UserId == userId && t.Token == trimmed, cancellationToken);
        if (entity is null)
        {
            return;
        }

        dbContext.DeviceTokens.Remove(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<NotificationPreferencesDto> GetPreferencesAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var stored = await dbContext.NotificationPreferences
            .AsNoTracking()
            .Where(p => p.UserId == userId)
            .ToListAsync(cancellationToken);

        var allTypes = GetAllPreferenceTypes();
        var items = allTypes.Select(type =>
        {
            var pref = stored.FirstOrDefault(p => p.Type == type);
            return new NotificationPreferenceDto
            {
                Type = type,
                InAppEnabled = ResolvePreference(pref?.InAppEnabled, defaultValue: true),
                PushEnabled = ResolvePreference(pref?.PushEnabled, defaultValue: true),
                EmailEnabled = ResolvePreference(
                    pref?.EmailEnabled,
                    GetDefaultEmailEnabled(type)),
            };
        }).ToList();

        return new NotificationPreferencesDto { Preferences = items };
    }

    public async Task UpdatePreferencesAsync(
        Guid userId,
        UpdateNotificationPreferencesRequest request,
        CancellationToken cancellationToken = default)
    {
        var allowed = GetAllPreferenceTypes().ToHashSet(StringComparer.Ordinal);
        foreach (var item in request.Preferences)
        {
            if (!allowed.Contains(item.Type))
            {
                throw new AppException($"Invalid notification type: {item.Type}", 400);
            }
        }

        var types = request.Preferences.Select(p => p.Type).ToList();
        var existingByType = await dbContext.NotificationPreferences
            .Where(p => p.UserId == userId && types.Contains(p.Type))
            .ToDictionaryAsync(p => p.Type, cancellationToken);

        foreach (var item in request.Preferences)
        {
            if (existingByType.TryGetValue(item.Type, out var existing))
            {
                existing.InAppEnabled = item.InAppEnabled;
                existing.PushEnabled = item.PushEnabled;
                existing.EmailEnabled = item.EmailEnabled;
                continue;
            }

            dbContext.NotificationPreferences.Add(new NotificationPreference
            {
                NotificationPreferenceId = Guid.NewGuid(),
                UserId = userId,
                Type = item.Type,
                InAppEnabled = item.InAppEnabled,
                PushEnabled = item.PushEnabled,
                EmailEnabled = item.EmailEnabled,
            });
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<Dictionary<Guid, NotificationPreference>> LoadPreferencesMapAsync(
        IReadOnlyList<Guid> userIds,
        string type,
        CancellationToken cancellationToken)
    {
        return await dbContext.NotificationPreferences
            .AsNoTracking()
            .Where(p => userIds.Contains(p.UserId) && p.Type == type)
            .ToDictionaryAsync(p => p.UserId, cancellationToken);
    }

    private static NotificationDto Map(Notification entity)
    {
        NotificationPayload? data = null;
        if (!string.IsNullOrWhiteSpace(entity.DataJson))
        {
            try
            {
                data = JsonSerializer.Deserialize<NotificationPayload>(entity.DataJson, JsonOptions);
            }
            catch
            {
                // Best effort for legacy rows.
            }
        }

        return new NotificationDto
        {
            NotificationId = entity.NotificationId,
            Type = entity.Type,
            Title = entity.Title,
            Body = entity.Body,
            Data = data,
            IsRead = entity.IsRead,
            ReadAt = entity.ReadAt,
            CreatedAt = entity.CreatedAt,
        };
    }

    private static IReadOnlyDictionary<string, string>? BuildPushData(
        string type,
        NotificationPayload payload)
    {
        var dict = new Dictionary<string, string> { ["type"] = type };
        if (payload.QuizId is not null) dict["quizId"] = payload.QuizId.Value.ToString();
        if (payload.ClassId is not null) dict["classId"] = payload.ClassId.Value.ToString();
        if (payload.AssignmentId is not null) dict["assignmentId"] = payload.AssignmentId.Value.ToString();
        if (payload.AiJobId is not null) dict["aiJobId"] = payload.AiJobId.Value.ToString();
        if (!string.IsNullOrWhiteSpace(payload.Route)) dict["route"] = payload.Route!;
        return dict;
    }

    private async Task SendNotificationEmailAsync(
        IEmailSender sender,
        string email,
        string language,
        string type,
        NotificationPayload payload,
        CancellationToken cancellationToken)
    {
        var (subject, plain, html) = type switch
        {
            NotificationTypes.QuizShared =>
                EmailTemplateBuilder.BuildQuizShared(language, payload),
            NotificationTypes.ClassJoined =>
                EmailTemplateBuilder.BuildClassJoined(language, payload),
            NotificationTypes.AssignmentCreated =>
                EmailTemplateBuilder.BuildAssignmentCreated(language, payload),
            NotificationTypes.AssignmentDueSoon =>
                EmailTemplateBuilder.BuildAssignmentDueSoon(language, payload),
            NotificationTypes.AiJobCompleted =>
                EmailTemplateBuilder.BuildAiJobCompleted(language, payload),
            NotificationTypes.AiJobFailed =>
                EmailTemplateBuilder.BuildAiJobFailed(language, payload),
            NotificationTypes.MembershipExpiring =>
                EmailTemplateBuilder.BuildMembershipExpiring(language, payload),
            NotificationTypes.MembershipExpired =>
                EmailTemplateBuilder.BuildMembershipExpired(language, payload),
            _ => default,
        };

        if (subject is null)
        {
            return;
        }

        await sender.SendAsync(email, subject, plain, html, cancellationToken);
    }

    private Task SendNotificationEmailAsync(
        string email,
        string language,
        string type,
        NotificationPayload payload,
        CancellationToken cancellationToken) =>
        SendNotificationEmailAsync(emailSender, email, language, type, payload, cancellationToken);

    private static IReadOnlyList<string> GetAllPreferenceTypes() =>
    [
        NotificationTypes.QuizShared,
        NotificationTypes.ClassJoined,
        NotificationTypes.AssignmentCreated,
        NotificationTypes.AssignmentDueSoon,
        NotificationTypes.AiJobCompleted,
        NotificationTypes.AiJobFailed,
        NotificationTypes.MembershipExpiring,
        NotificationTypes.MembershipExpired,
    ];

    private static bool ResolvePreference(bool? stored, bool defaultValue) =>
        stored ?? defaultValue;

    private static bool GetDefaultEmailEnabled(string type) =>
        type is NotificationTypes.MembershipExpiring
            or NotificationTypes.MembershipExpired;
}
