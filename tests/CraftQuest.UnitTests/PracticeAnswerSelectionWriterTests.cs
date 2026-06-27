using CraftQuest.Application.Services;
using CraftQuest.Domain.Entities;

namespace CraftQuest.UnitTests;

public class PracticeAnswerSelectionWriterTests
{
    [Fact]
    public void NormalizeSelectedIds_SingleChoice_KeepsOnlyLastId()
    {
        var ids = new List<Guid> { Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid() };

        var normalized = PracticeAnswerSelectionWriter.NormalizeSelectedIds(ids, supportsMultipleCorrectAnswers: false);

        Assert.Single(normalized);
        Assert.Equal(ids[^1], normalized[0]);
    }

    [Fact]
    public void ApplySelection_SingleChoice_ReplacesPreviousSelection()
    {
        var optionA = Guid.NewGuid();
        var optionB = Guid.NewGuid();
        var optionC = Guid.NewGuid();
        var snapshot = new PracticeQuestionSnapshot
        {
            PracticeQuestionSnapshotId = Guid.NewGuid(),
            PracticeSessionId = Guid.NewGuid(),
            QuestionId = Guid.NewGuid(),
            AnswerOptionSnapshots =
            [
                new PracticeAnswerOptionSnapshot
                {
                    AnswerOptionId = optionA,
                    WasSelected = true,
                },
                new PracticeAnswerOptionSnapshot
                {
                    AnswerOptionId = optionB,
                    WasSelected = true,
                },
                new PracticeAnswerOptionSnapshot
                {
                    AnswerOptionId = optionC,
                    WasSelected = false,
                },
            ],
        };

        var now = DateTime.UtcNow;
        PracticeAnswerSelectionWriter.ApplySelection(
            snapshot,
            [optionC],
            supportsMultipleCorrectAnswers: false,
            now);

        Assert.False(snapshot.AnswerOptionSnapshots.Single(a => a.AnswerOptionId == optionA).WasSelected);
        Assert.False(snapshot.AnswerOptionSnapshots.Single(a => a.AnswerOptionId == optionB).WasSelected);
        Assert.True(snapshot.AnswerOptionSnapshots.Single(a => a.AnswerOptionId == optionC).WasSelected);
    }
}
