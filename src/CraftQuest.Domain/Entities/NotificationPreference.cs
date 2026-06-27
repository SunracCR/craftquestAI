namespace CraftQuest.Domain.Entities;

public class NotificationPreference
{
    public Guid NotificationPreferenceId { get; set; }
    public Guid UserId { get; set; }
    public string Type { get; set; } = string.Empty;
    public bool InAppEnabled { get; set; } = true;
    public bool PushEnabled { get; set; } = true;
    public bool EmailEnabled { get; set; } = false;

    public User User { get; set; } = null!;
}
