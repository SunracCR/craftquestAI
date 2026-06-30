using CraftQuest.Application.Services;
using CraftQuest.Application.Services.Quizzes;
using CraftQuest.Domain.Entities;

namespace CraftQuest.Infrastructure.Services.Practice;

internal static class PracticeSessionSnapshotBuilder
{
    private const string QuestionImageKey = "QUESTION_IMAGE";

    public static void PopulateQuestionSnapshots(
        PracticeSession session,
        IReadOnlyList<Question> questionList,
        DateTime? createdAt = null)
    {
        var timestamp = createdAt ?? DateTime.UtcNow;
        var displayOrder = 0;

        foreach (var question in questionList)
        {
            displayOrder++;
            var snapshotId = Guid.NewGuid();
            var seed = Guid.NewGuid().ToString("N");

            var allOptions = question.AnswerOptions.Where(o => o.IsActive).ToList();
            var stemOption = allOptions.FirstOrDefault(o =>
                string.Equals(o.StableKey, QuestionImageKey, StringComparison.OrdinalIgnoreCase));
            var selectableOptions = allOptions
                .Where(o => !string.Equals(o.StableKey, QuestionImageKey, StringComparison.OrdinalIgnoreCase))
                .ToList();

            var correctIds = question.CorrectAnswerOptions
                .Select(c => c.AnswerOptionId)
                .ToHashSet();

            var orderedOptions = question.RandomizeAnswerOptions
                ? PracticeSessionOrdering.ShuffleAnswerOptions(selectableOptions, seed)
                : selectableOptions.OrderBy(o => o.DefaultSortOrder).ToList();

            var labels = AnswerGradingService.BuildDisplayLabels(orderedOptions.Count);
            var answerSnapshots = new List<PracticeAnswerOptionSnapshot>();

            if (stemOption is not null)
            {
                answerSnapshots.Add(new PracticeAnswerOptionSnapshot
                {
                    PracticeAnswerOptionSnapshotId = Guid.NewGuid(),
                    PracticeQuestionSnapshotId = snapshotId,
                    AnswerOptionId = stemOption.AnswerOptionId,
                    StableKeySnapshot = stemOption.StableKey,
                    DisplayOrder = 0,
                    DisplayLabel = string.Empty,
                    AnswerTextSnapshot = stemOption.AnswerText,
                    MediaAssetIdSnapshot = stemOption.MediaAssetId,
                    IsCorrectSnapshot = false,
                    WasSelected = false,
                    CreatedAt = timestamp,
                });
            }

            for (var i = 0; i < orderedOptions.Count; i++)
            {
                var option = orderedOptions[i];
                answerSnapshots.Add(new PracticeAnswerOptionSnapshot
                {
                    PracticeAnswerOptionSnapshotId = Guid.NewGuid(),
                    PracticeQuestionSnapshotId = snapshotId,
                    AnswerOptionId = option.AnswerOptionId,
                    StableKeySnapshot = option.StableKey,
                    DisplayOrder = i + 1,
                    DisplayLabel = labels[i],
                    AnswerTextSnapshot = option.AnswerText,
                    MediaAssetIdSnapshot = option.MediaAssetId,
                    IsCorrectSnapshot = correctIds.Contains(option.AnswerOptionId),
                    WasSelected = false,
                    CreatedAt = timestamp,
                });
            }

            var (justificationText, justificationSourcesJson) =
                QuestionJustificationMapper.BuildPracticeSnapshot(question.Justification);

            session.QuestionSnapshots.Add(new PracticeQuestionSnapshot
            {
                PracticeQuestionSnapshotId = snapshotId,
                PracticeSessionId = session.PracticeSessionId,
                QuestionId = question.QuestionId,
                QuestionTypeCodeSnapshot = question.QuestionType.Code,
                QuestionTextSnapshot = question.QuestionText,
                PointsPossible = question.Points,
                DisplayOrder = displayOrder,
                AnswerStatus = "unanswered",
                RandomizationSeed = seed,
                JustificationTextSnapshot = justificationText,
                JustificationSourcesSnapshot = justificationSourcesJson,
                CreatedAt = timestamp,
                AnswerOptionSnapshots = answerSnapshots,
            });
        }
    }

    public static int CountAnswerOptions(PracticeSession session) =>
        session.QuestionSnapshots.Sum(q => q.AnswerOptionSnapshots.Count);

    public static Guid GetFirstQuestionSnapshotId(PracticeSession session) =>
        session.QuestionSnapshots
            .OrderBy(q => q.DisplayOrder)
            .First()
            .PracticeQuestionSnapshotId;
}
