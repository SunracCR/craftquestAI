namespace CraftQuest.Domain.Entities;

public class Quiz
{
    public Guid QuizId { get; set; }
    public Guid CreatedByUserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Visibility { get; set; } = "private";
    public string PublicationStatus { get; set; } = "draft";
    public decimal DefaultQuestionPoints { get; set; } = 1;
    public bool RandomizeQuestions { get; set; }
    public bool DefaultRandomizeAnswerOptions { get; set; } = true;
    public bool IsCurated { get; set; }
    public string? TargetCountryCode { get; set; }
    public Guid? FolderId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? DeletedAt { get; set; }

    public ICollection<Question> Questions { get; set; } = [];
}
