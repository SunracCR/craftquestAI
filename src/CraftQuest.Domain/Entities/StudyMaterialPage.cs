namespace CraftQuest.Domain.Entities;

public class StudyMaterialPage
{
    public Guid StudyMaterialPageId { get; set; }
    public Guid StudyMaterialId { get; set; }
    public int PageNumber { get; set; }
    public string? ExtractedText { get; set; }
    public int WordCount { get; set; }
    public bool HasEmbeddedImages { get; set; }
    public string ExtractionQuality { get; set; } = "good";
    public string? ImageBlobPath { get; set; }

    public StudyMaterial StudyMaterial { get; set; } = null!;
}
