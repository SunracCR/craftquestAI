namespace CraftQuest.Domain.Entities;

public class Assignment
{
    public Guid AssignmentId { get; set; }
    public Guid ClassId { get; set; }
    public Guid QuizId { get; set; }
    public Guid CreatedByUserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Instructions { get; set; }
    public DateTime? StartsAt { get; set; }
    public DateTime? DueAt { get; set; }
    public int? MaxAttempts { get; set; }
    public string ShowCorrectAnswersMode { get; set; } = "after_due_date";
    public string Status { get; set; } = "active";
    public DateTime CreatedAt { get; set; }

    public TeacherClass Class { get; set; } = null!;
    public Quiz Quiz { get; set; } = null!;
    public User CreatedByUser { get; set; } = null!;
    public ICollection<PracticeSession> PracticeSessions { get; set; } = [];
}
