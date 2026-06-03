using CraftQuest.Domain.Constants;

namespace CraftQuest.Domain.Entities;

public class PrepCategory
{
    public Guid CategoryId { get; set; }
    public Guid? ParentCategoryId { get; set; }
    public string CategoryType { get; set; } = PrepPlusConstants.CategoryTypes.Geographic;
    public string Slug { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? CountryCode { get; set; }
    public string? IconKey { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public PrepCategory? Parent { get; set; }
    public ICollection<PrepCategory> Children { get; set; } = [];
    public ICollection<PrepCatalogItem> CatalogItems { get; set; } = [];
}
