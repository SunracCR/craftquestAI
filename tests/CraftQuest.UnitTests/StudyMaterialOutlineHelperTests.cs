using CraftQuest.Application.Contracts;
using CraftQuest.Infrastructure.StudyMaterials;

namespace CraftQuest.UnitTests;

public class StudyMaterialOutlineHelperTests
{
    [Fact]
    public void DetectNeedsOcr_WhenMostPagesEmpty_ReturnsTrue()
    {
        var pages = Enumerable.Range(1, 10)
            .Select(i => new ExtractedPage
            {
                PageNumber = i,
                Text = i <= 7 ? "" : "Some words here",
                WordCount = i <= 7 ? 0 : 5,
                ExtractionQuality = i <= 7 ? "empty" : "low",
            })
            .ToList();

        Assert.True(StudyMaterialOutlineHelper.DetectNeedsOcr(pages));
    }

    [Fact]
    public void DetectNeedsOcr_WhenTextRich_ReturnsFalse()
    {
        var pages = new List<ExtractedPage>
        {
            new()
            {
                PageNumber = 1,
                Text = "Mitochondria is the powerhouse of the cell with many details.",
                WordCount = 12,
                ExtractionQuality = "good",
            },
        };

        Assert.False(StudyMaterialOutlineHelper.DetectNeedsOcr(pages));
    }

    [Fact]
    public void HasMeaningfulExtractableContent_WhenManySparsePagesButEnoughTotalWords_ReturnsTrue()
    {
        var pages = Enumerable.Range(1, 100)
            .Select(i => new ExtractedPage
            {
                PageNumber = i,
                Text = i <= 85 ? "" : "Paragraph with enough words for extraction testing.",
                WordCount = i <= 85 ? 0 : 8,
                ExtractionQuality = i <= 85 ? "empty" : "good",
            })
            .ToList();

        Assert.True(StudyMaterialOutlineHelper.DetectNeedsOcr(pages));
        Assert.True(StudyMaterialOutlineHelper.HasMeaningfulExtractableContent(pages));
        Assert.False(StudyMaterialOutlineHelper.ShouldRejectAsUnselectable(pages));
    }

    [Fact]
    public void ShouldRejectAsUnselectable_WhenAlmostNoText_ReturnsTrue()
    {
        var pages = Enumerable.Range(1, 20)
            .Select(i => new ExtractedPage
            {
                PageNumber = i,
                Text = "",
                WordCount = 0,
                ExtractionQuality = "empty",
            })
            .ToList();

        Assert.True(StudyMaterialOutlineHelper.ShouldRejectAsUnselectable(pages));
    }
}
