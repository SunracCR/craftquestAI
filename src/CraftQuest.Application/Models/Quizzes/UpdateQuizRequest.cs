using System.ComponentModel.DataAnnotations;

namespace CraftQuest.Application.Models.Quizzes;

public class UpdateQuizRequest
{
    [MaxLength(220)]
    public string? Title { get; set; }

    [MaxLength(1000)]
    public string? Description { get; set; }

    public string? Visibility { get; set; }
    public string? PublicationStatus { get; set; }
    public bool? RandomizeQuestions { get; set; }
    public bool? DefaultRandomizeAnswerOptions { get; set; }
    public Guid? FolderId { get; set; }
    public bool ClearFolder { get; set; }
}
