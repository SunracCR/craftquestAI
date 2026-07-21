namespace CraftQuest.Domain.Entities;

public class QuizAccess
{
    public Guid QuizAccessId { get; set; }
    public Guid UserId { get; set; }
    public Guid QuizId { get; set; }
    public Guid? ClassId { get; set; }
    public Guid? AssignmentId { get; set; }
    public string AccessType { get; set; } = "redeemed";
    public Guid? GrantedByShareCodeId { get; set; }
    public DateTime GrantedAt { get; set; }
    public DateTime? LastPracticedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public bool IsLifetimeAccess { get; set; }
    public Guid? GrantedByPurchaseId { get; set; }
    public Guid? PrepCatalogItemId { get; set; }

    public User User { get; set; } = null!;
    public Purchase? GrantedByPurchase { get; set; }
    public PrepCatalogItem? PrepCatalogItem { get; set; }
    public Quiz Quiz { get; set; } = null!;
    public ShareCode? GrantedByShareCode { get; set; }
}
