using System.ComponentModel.DataAnnotations;

namespace CraftQuest.Application.Models.Quizzes;

public class CreateQuizRequest
{
    [Required, MaxLength(220)]
    public string Title { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string? Description { get; set; }

    public string Visibility { get; set; } = "private";
    public bool RandomizeQuestions { get; set; }
    public bool DefaultRandomizeAnswerOptions { get; set; } = true;
}
