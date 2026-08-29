namespace CraftQuest.Domain.Entities;

public class Question
{
    public Guid QuestionId { get; set; }
    public Guid QuizId { get; set; }
    public Guid? QuizSectionId { get; set; }
    public Guid? QuizTopicId { get; set; }
    public int QuestionTypeId { get; set; }
    public string QuestionText { get; set; } = string.Empty;
    public decimal Points { get; set; } = 1;
    public int SortOrder { get; set; }
    public string? Difficulty { get; set; }
    public string ExplanationVisibility { get; set; } = "never";
    public bool RandomizeAnswerOptions { get; set; } = true;
    public string ScoringPolicy { get; set; } = "strict";
    public string ReviewStatus { get; set; } = "approved";
    public bool IsGeneratedByAi { get; set; }
    public Guid CreatedByUserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? DeletedAt { get; set; }

    public Quiz Quiz { get; set; } = null!;
    public QuizSection? QuizSection { get; set; }
    public QuizTopic? QuizTopic { get; set; }
    public QuestionType QuestionType { get; set; } = null!;
    public ICollection<QuestionAnswerOption> AnswerOptions { get; set; } = [];
    public ICollection<QuestionCorrectAnswerOption> CorrectAnswerOptions { get; set; } = [];
    public QuestionJustification? Justification { get; set; }
}
