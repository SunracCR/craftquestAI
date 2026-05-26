namespace CraftQuest.Domain.Entities;

public class GuestVisit
{
    public Guid GuestVisitId { get; set; }
    public Guid QuizId { get; set; }
    public string Token { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime LastActivityAt { get; set; }

    public Quiz Quiz { get; set; } = null!;
    public ICollection<PracticeSession> PracticeSessions { get; set; } = [];
}
