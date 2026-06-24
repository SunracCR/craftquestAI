namespace CraftQuest.Domain.Entities;

public class QuizFolder
{
    public Guid QuizFolderId { get; set; }
    public Guid OwnerUserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public Guid? ParentFolderId { get; set; }
    public int Depth { get; set; }
    public int SortOrder { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? DeletedAt { get; set; }
}
