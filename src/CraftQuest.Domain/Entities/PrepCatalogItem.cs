namespace CraftQuest.Domain.Entities;

public class PrepCatalogItem
{
    public Guid CatalogItemId { get; set; }
    public Guid QuizId { get; set; }
    public Guid CategoryId { get; set; }
    public string? TitleOverride { get; set; }
    public string? Description { get; set; }
    public Guid? CoverMediaId { get; set; }
    public string? TagsJson { get; set; }
    public string? InstitutionTag { get; set; }
    public DateTime? ListingStartsAt { get; set; }
    public DateTime? ListingEndsAt { get; set; }
    public bool IsPublished { get; set; }
    public DateTime? PublishedAt { get; set; }
    public bool IsDeleted { get; set; }
    public Guid CreatedByUserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public Quiz Quiz { get; set; } = null!;
    public PrepCategory Category { get; set; } = null!;
    public MediaAsset? CoverMedia { get; set; }
    public User CreatedByUser { get; set; } = null!;
    public ICollection<PrepAccessOffer> AccessOffers { get; set; } = [];
    public ICollection<PrepSampleQuestion> SampleQuestions { get; set; } = [];
}
