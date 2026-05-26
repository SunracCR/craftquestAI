namespace CraftQuest.Application.Models.Sharing;

public class CreateShareCodeRequest
{
    /// <summary>Opcional; el servidor asigna <c>class_capacity</c> para compartir multiuso.</summary>
    public string? CodeType { get; set; }
    public int? MaxRedemptions { get; set; }
    public DateTime? ExpiresAt { get; set; }
    /// <summary>
    /// Profesor: "guest_open" (cualquiera) o "group_only" (requiere <see cref="ClassId"/>).
    /// Estudiante: se ignora; siempre multiuso abierto.
    /// </summary>
    public string? AccessPolicy { get; set; }
    public Guid? ClassId { get; set; }
}

public sealed class ShareCodeDto
{
    public required Guid ShareCodeId { get; init; }
    public required string Code { get; init; }
    public required Guid QuizId { get; init; }
    public required string CodeType { get; init; }
    public required int MaxRedemptions { get; init; }
    public required int RedemptionsCount { get; init; }
    public required string Status { get; init; }
    public required string AccessPolicy { get; init; }
    public Guid? ClassId { get; init; }
    public DateTime? ExpiresAt { get; init; }
    public bool IsExisting { get; init; }
}

public class RedeemShareCodeRequest
{
    public string Code { get; set; } = string.Empty;
}

public sealed class RedeemShareCodeResultDto
{
    public required Guid QuizId { get; init; }
    public Guid? ClassId { get; init; }
    public Guid? AssignmentId { get; init; }
    public required string QuizTitle { get; init; }
    public bool AlreadyInSharedList { get; init; }
}

public sealed class AccessibleQuizDto
{
    public required Guid QuizId { get; init; }
    public required string Title { get; init; }
    public string? Description { get; init; }
    public required string PublicationStatus { get; init; }
    public required int QuestionCount { get; init; }
    public required string AccessType { get; init; }
    public required Guid SharedByUserId { get; init; }
    public string? SharedByDisplayName { get; init; }
}

public class InviteUsersRequest
{
    public List<string> Emails { get; set; } = [];
}

public sealed class InviteUsersResultDto
{
    public required IReadOnlyList<InviteUserResultItemDto> Results { get; init; }
}

public sealed class InviteUserResultItemDto
{
    public required string Email { get; init; }
    /// <summary>invited | already_had_access | not_found | invalid_email | slot_limit | self</summary>
    public required string Outcome { get; init; }
    public string? DisplayName { get; init; }
}
