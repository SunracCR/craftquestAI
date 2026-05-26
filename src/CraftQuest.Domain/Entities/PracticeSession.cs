namespace CraftQuest.Domain.Entities;

public class PracticeSession
{
    public Guid PracticeSessionId { get; set; }
    public Guid? StudentUserId { get; set; }
    public Guid QuizId { get; set; }
    public Guid? ClassId { get; set; }
    public Guid? AssignmentId { get; set; }
    public DateTime StartedAt { get; set; }
    public DateTime? FinishedAt { get; set; }
    public int? DurationSeconds { get; set; }
    public decimal ScoreObtained { get; set; }
    public decimal ScorePossible { get; set; }
    public int CorrectAnswers { get; set; }
    public int IncorrectAnswers { get; set; }
    public int OmittedAnswers { get; set; }
    public string Status { get; set; } = "in_progress";
    public string RandomizationStrategy { get; set; } = "server_random";
    public bool ShowElapsedTimer { get; set; }
    public int? CurrentQuestionIndex { get; set; }
    public int ElapsedSecondsBeforePause { get; set; }
    public DateTime? PausedAt { get; set; }
    public DateTime? LastActivityAt { get; set; }
    public DateTime CreatedAt { get; set; }

    public Guid? GuestVisitId { get; set; }

    public User? StudentUser { get; set; }
    public Quiz Quiz { get; set; } = null!;
    public GuestVisit? GuestVisit { get; set; }
    public ICollection<PracticeQuestionSnapshot> QuestionSnapshots { get; set; } = [];
}
