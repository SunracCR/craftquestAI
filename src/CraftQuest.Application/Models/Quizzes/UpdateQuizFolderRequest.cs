using System.ComponentModel.DataAnnotations;

namespace CraftQuest.Application.Models.Quizzes;

public class UpdateQuizFolderRequest
{
    [MaxLength(160)]
    public string? Name { get; set; }

    /// <summary>Set to move folder; omit to keep current parent. Use null to move to root.</summary>
    public Guid? ParentFolderId { get; set; }

    public bool ClearParentFolder { get; set; }
}
