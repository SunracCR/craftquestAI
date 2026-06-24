using System.ComponentModel.DataAnnotations;

namespace CraftQuest.Application.Models.Quizzes;

public class CreateQuizFolderRequest
{
    [Required]
    [MaxLength(160)]
    public required string Name { get; set; }

    public Guid? ParentFolderId { get; set; }
}
