namespace CraftQuest.Domain.Entities;

public class PracticeAnswerOptionSnapshot
{
    public Guid PracticeAnswerOptionSnapshotId { get; set; }
    public Guid PracticeQuestionSnapshotId { get; set; }
    public Guid AnswerOptionId { get; set; }
    public string? StableKeySnapshot { get; set; }
    public int DisplayOrder { get; set; }
    public string DisplayLabel { get; set; } = string.Empty;
    public string? AnswerTextSnapshot { get; set; }
    public Guid? MediaAssetIdSnapshot { get; set; }
    public bool IsCorrectSnapshot { get; set; }
    public bool WasSelected { get; set; }
    public DateTime? SelectedAt { get; set; }
    public DateTime CreatedAt { get; set; }

    public PracticeQuestionSnapshot PracticeQuestionSnapshot { get; set; } = null!;
}
