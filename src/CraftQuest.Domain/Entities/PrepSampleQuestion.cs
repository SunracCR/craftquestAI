namespace CraftQuest.Domain.Entities;

public class PrepSampleQuestion
{
    public Guid CatalogItemId { get; set; }
    public Guid QuestionId { get; set; }
    public int SortOrder { get; set; }

    public PrepCatalogItem CatalogItem { get; set; } = null!;
    public Question Question { get; set; } = null!;
}
