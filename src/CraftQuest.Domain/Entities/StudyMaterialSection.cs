namespace CraftQuest.Domain.Entities;

public class StudyMaterialSection
{
    public Guid StudyMaterialSectionId { get; set; }
    public Guid StudyMaterialId { get; set; }
    public string Title { get; set; } = string.Empty;
    public int PageFrom { get; set; }
    public int PageTo { get; set; }
    public int SortOrder { get; set; }

    public StudyMaterial StudyMaterial { get; set; } = null!;
}
