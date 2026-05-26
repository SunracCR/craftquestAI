namespace CraftQuest.Domain.Entities;

public class ShareCode
{
    public Guid ShareCodeId { get; set; }
    public string Code { get; set; } = string.Empty;
    public Guid? QuizId { get; set; }
    public Guid? ClassId { get; set; }
    public Guid? AssignmentId { get; set; }
    public Guid CreatedByUserId { get; set; }
    public string CodeType { get; set; } = "single_use";
    public int MaxRedemptions { get; set; } = 1;
    public int RedemptionsCount { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public string Status { get; set; } = "active";
    /// <summary>
    /// Política de acceso: "guest_open" | "registered_open" | "group_only" | "direct_user"
    /// </summary>
    public string AccessPolicy { get; set; } = "registered_open";
    public DateTime CreatedAt { get; set; }

    public Quiz? Quiz { get; set; }
    public User CreatedByUser { get; set; } = null!;
}
