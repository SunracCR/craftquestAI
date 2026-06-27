using System.Text.Json.Serialization;

namespace CraftQuest.Application.Models.Notifications;

public sealed class NotificationPayload
{
    [JsonPropertyName("quizId")]
    public Guid? QuizId { get; init; }

    [JsonPropertyName("quizTitle")]
    public string? QuizTitle { get; init; }

    [JsonPropertyName("classId")]
    public Guid? ClassId { get; init; }

    [JsonPropertyName("className")]
    public string? ClassName { get; init; }

    [JsonPropertyName("assignmentId")]
    public Guid? AssignmentId { get; init; }

    [JsonPropertyName("assignmentTitle")]
    public string? AssignmentTitle { get; init; }

    [JsonPropertyName("aiJobId")]
    public Guid? AiJobId { get; init; }

    [JsonPropertyName("dueAtLabel")]
    public string? DueAtLabel { get; init; }

    [JsonPropertyName("planName")]
    public string? PlanName { get; init; }

    [JsonPropertyName("daysRemaining")]
    public int? DaysRemaining { get; init; }

    [JsonPropertyName("ownerName")]
    public string? OwnerName { get; init; }

    [JsonPropertyName("route")]
    public string? Route { get; init; }
}

public sealed class NotificationDto
{
    public required Guid NotificationId { get; init; }
    public required string Type { get; init; }
    public required string Title { get; init; }
    public required string Body { get; init; }
    public NotificationPayload? Data { get; init; }
    public required bool IsRead { get; init; }
    public DateTime? ReadAt { get; init; }
    public required DateTime CreatedAt { get; init; }
}

public sealed class NotificationListResultDto
{
    public required IReadOnlyList<NotificationDto> Items { get; init; }
    public string? NextCursor { get; init; }
    public required int UnreadCount { get; init; }
}

public sealed class UnreadCountDto
{
    public required int Count { get; init; }
}

public sealed class RegisterDeviceTokenRequest
{
    public required string Token { get; set; }
    public required string Platform { get; set; }
}

public sealed class NotificationPreferenceDto
{
    public required string Type { get; init; }
    public required bool InAppEnabled { get; init; }
    public required bool PushEnabled { get; init; }
    public required bool EmailEnabled { get; init; }
}

public sealed class NotificationPreferencesDto
{
    public required IReadOnlyList<NotificationPreferenceDto> Preferences { get; init; }
}

public sealed class UpdateNotificationPreferencesRequest
{
    public required IReadOnlyList<NotificationPreferenceDto> Preferences { get; set; }
}

public sealed class AssignmentCreatedOutboxPayload
{
    public Guid AssignmentId { get; set; }
    public Guid ClassId { get; set; }
}
