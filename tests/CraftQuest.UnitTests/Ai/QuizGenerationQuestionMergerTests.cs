using CraftQuest.Application.Models.Imports;
using CraftQuest.Infrastructure.Services.Ai;

namespace CraftQuest.UnitTests.Ai;

public class QuizGenerationQuestionMergerTests
{
    [Fact]
    public void Merge_DeduplicatesByQuestionText()
    {
        var partials = new[]
        {
            new CqifDocument
            {
                Questions =
                [
                    new CqifQuestion { Text = "What is ATP?", Type = "single_choice" },
                    new CqifQuestion { Text = "What is DNA?", Type = "single_choice" },
                ],
            },
            new CqifDocument
            {
                Questions =
                [
                    new CqifQuestion { Text = "What is ATP?", Type = "true_false" },
                    new CqifQuestion { Text = "What is RNA?", Type = "single_choice" },
                ],
            },
        };

        var merged = QuizGenerationQuestionMerger.Merge(partials, targetQuestionCount: 10, deduplicateByText: true);

        Assert.Equal(3, merged.Questions.Count);
        Assert.Equal("ai-gen-001", merged.Questions[0].ExternalId);
        Assert.Equal(1, merged.Questions[0].Order);
    }

    [Fact]
    public void GroupOutlineByChunk_AssignsByChunkIndex()
    {
        var items = new[]
        {
            new QuizGenerationOutlineItem(1, "A", "single_choice", 1),
            new QuizGenerationOutlineItem(2, "B", "single_choice", 2),
            new QuizGenerationOutlineItem(3, "C", "single_choice", 2),
        };

        var groups = QuizGenerationQuestionMerger.GroupOutlineByChunk(items, chunkCount: 2);

        Assert.Single(groups[0]);
        Assert.Equal(2, groups[1].Count);
    }
}
