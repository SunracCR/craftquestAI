using System.ComponentModel.DataAnnotations;

namespace CraftQuest.Application.Models.Quizzes;

public class CreateAnswerOptionRequest
{
    [Required, MaxLength(100)]
    public string ClientKey { get; set; } = string.Empty;

    public string? Text { get; set; }
    public Guid? MediaAssetId { get; set; }
    public int DefaultSortOrder { get; set; }
}
