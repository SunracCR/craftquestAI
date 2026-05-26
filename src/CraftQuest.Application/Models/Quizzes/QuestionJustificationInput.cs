namespace CraftQuest.Application.Models.Quizzes;

public class QuestionJustificationInput
{
    public string? Text { get; set; }
    public string? SourceUrl { get; set; }
    public string Visibility { get; set; } = "after_quiz";
}
