namespace CraftQuest.Domain.Entities;

/// <summary>Idempotencia de webhooks de proveedores de pago.</summary>
public class ProviderWebhookEvent
{
    public Guid ProviderWebhookEventId { get; set; }
    public string ProviderCode { get; set; } = string.Empty;
    public string EventId { get; set; } = string.Empty;
    public string EventType { get; set; } = string.Empty;
    public DateTime ProcessedAt { get; set; }
}
