using CraftQuest.Infrastructure.Services.Ai;

namespace CraftQuest.UnitTests.Ai;

public class StudyMaterialTextChunkerTests
{
    [Fact]
    public void SplitIntoChunks_ShortText_ReturnsSingleChunk()
    {
        var text = string.Join(' ', Enumerable.Repeat("word", 100));
        var chunks = StudyMaterialTextChunker.SplitIntoChunks(text, 3800);

        Assert.Single(chunks);
        Assert.Equal(text, chunks[0]);
    }

    [Fact]
    public void SplitIntoChunks_RespectsPageMarkers()
    {
        var page1 = string.Join(' ', Enumerable.Repeat("alpha", 2000));
        var page2 = string.Join(' ', Enumerable.Repeat("beta", 2000));
        var source = $"--- Page 1 ---\n{page1}\n\n--- Page 2 ---\n{page2}";

        var chunks = StudyMaterialTextChunker.SplitIntoChunks(source, 2500);

        Assert.Equal(2, chunks.Count);
        Assert.Contains("Page 1", chunks[0], StringComparison.Ordinal);
        Assert.Contains("Page 2", chunks[1], StringComparison.Ordinal);
    }

    [Fact]
    public void DistributeQuestionCounts_SpreadsRemainderToLastChunk()
    {
        var counts = StudyMaterialTextChunker.DistributeQuestionCounts(15, 4);

        Assert.Equal([3, 3, 3, 6], counts);
        Assert.Equal(15, counts.Sum());
    }

    [Fact]
    public void DistributeQuestionCounts_SingleChunkGetsAll()
    {
        var counts = StudyMaterialTextChunker.DistributeQuestionCounts(8, 1);

        Assert.Equal([8], counts);
    }
}
