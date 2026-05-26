namespace CraftQuest.Domain.Entities;

public class UserSubscription
{
    public Guid UserSubscriptionId { get; set; }
    public Guid UserId { get; set; }
    public int PlanId { get; set; }
    public string Status { get; set; } = "active";
    public DateTime StartedAt { get; set; }
    public DateTime? EndsAt { get; set; }
    public string? ProviderCode { get; set; }
    public string? ProviderSubscriptionId { get; set; }
    public DateTime CreatedAt { get; set; }

    public User User { get; set; } = null!;
    public Plan Plan { get; set; } = null!;
}
