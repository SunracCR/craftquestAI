namespace CraftQuest.Application.Models.Quizzes;

public class QuestionJustificationInput
{
    public string? Text { get; set; }
    public string Visibility { get; set; } = "never";
    public List<QuestionJustificationSourceInput> Sources { get; set; } = [];
}

public class QuestionJustificationSourceInput
{
    public string? Title { get; set; }
    public string? SourceUrl { get; set; }
    public string? Provider { get; set; }
    public string? Snippet { get; set; }
    public int? PageNumber { get; set; }
    public Guid? StudyMaterialId { get; set; }
    public bool IsPrimary { get; set; }
}
