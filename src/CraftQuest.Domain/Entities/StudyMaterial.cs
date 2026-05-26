namespace CraftQuest.Domain.Entities;

public class StudyMaterial
{
    public Guid StudyMaterialId { get; set; }
    public Guid UploadedByUserId { get; set; }
    public Guid? MediaAssetId { get; set; }
    public string? OriginalText { get; set; }
    public string? EditedExtractedText { get; set; }
    public string FileType { get; set; } = string.Empty;
    public string ProcessingStatus { get; set; } = "pending";
    public Guid? GeneratedQuizId { get; set; }
    public string? Title { get; set; }
    public string? OriginalFileName { get; set; }
    public long? FileSizeBytes { get; set; }
    public int? PageCount { get; set; }
    public int? WordCount { get; set; }
    public string? LanguageCode { get; set; }
    public string? ErrorMessage { get; set; }
    public bool NeedsOcr { get; set; }
    public string? BlobPath { get; set; }
    public DateTime? RetentionExpiresAt { get; set; }
    public bool IsPinned { get; set; }
    public int? SelectionPageFrom { get; set; }
    public int? SelectionPageTo { get; set; }
    public string? SelectionTopic { get; set; }
    public DateTime CreatedAt { get; set; }

    public User UploadedByUser { get; set; } = null!;
    public MediaAsset? MediaAsset { get; set; }
    public Quiz? GeneratedQuiz { get; set; }
    public ICollection<StudyMaterialPage> Pages { get; set; } = [];
    public ICollection<StudyMaterialSection> Sections { get; set; } = [];
}
