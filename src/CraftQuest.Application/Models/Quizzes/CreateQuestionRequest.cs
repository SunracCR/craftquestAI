using System.ComponentModel.DataAnnotations;

namespace CraftQuest.Application.Models.Quizzes;

public class CreateQuestionRequest
{
    [Required]
    public string QuestionType { get; set; } = string.Empty;

    public Guid? SectionId { get; set; }

    [Required]
    public string Text { get; set; } = string.Empty;

    public decimal Points { get; set; } = 1;
    public bool RandomizeAnswerOptions { get; set; } = true;
    public string ScoringPolicy { get; set; } = "strict";

    [MinLength(2)]
    public List<CreateAnswerOptionRequest> AnswerOptions { get; set; } = [];

    [MinLength(1)]
    public List<string> CorrectAnswerKeys { get; set; } = [];

    public QuestionJustificationInput? Justification { get; set; }

    public bool IsGeneratedByAi { get; set; }
}
