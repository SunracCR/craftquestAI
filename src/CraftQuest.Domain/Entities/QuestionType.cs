namespace CraftQuest.Domain.Entities;

public class QuestionType
{
    public int QuestionTypeId { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool SupportsMultipleCorrectAnswers { get; set; }
    public bool SupportsImages { get; set; }
    public bool RequiresOptions { get; set; } = true;
    public bool IsActive { get; set; } = true;

    public ICollection<Question> Questions { get; set; } = [];
}