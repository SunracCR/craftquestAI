namespace CraftQuest.Domain.Entities;

public class PracticeQuestionSnapshot
{
    public Guid PracticeQuestionSnapshotId { get; set; }
    public Guid PracticeSessionId { get; set; }
    public Guid QuestionId { get; set; }
    public string QuestionTypeCodeSnapshot { get; set; } = string.Empty;
    public string QuestionTextSnapshot { get; set; } = string.Empty;
    public string? QuizSectionNameSnapshot { get; set; }
    public decimal PointsPossible { get; set; }
    public decimal PointsAwarded { get; set; }
    public int DisplayOrder { get; set; }
    public string AnswerStatus { get; set; } = "unanswered";
    public bool? IsCorrect { get; set; }
    public int? TimeSpentSeconds { get; set; }
    public string? RandomizationSeed { get; set; }
    public DateTime? SubmittedAt { get; set; }
    public DateTime CreatedAt { get; set; }

    public PracticeSession PracticeSession { get; set; } = null!;
    public ICollection<PracticeAnswerOptionSnapshot> AnswerOptionSnapshots { get; set; } = [];
}
