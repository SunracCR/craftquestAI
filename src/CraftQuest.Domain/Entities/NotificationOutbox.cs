namespace CraftQuest.Domain.Entities;

public class NotificationOutbox
{
    public Guid NotificationOutboxId { get; set; }
    public string EventType { get; set; } = string.Empty;
    public string PayloadJson { get; set; } = string.Empty;
    public string Status { get; set; } = "pending";
    public DateTime CreatedAt { get; set; }
    public DateTime? ProcessedAt { get; set; }
}
