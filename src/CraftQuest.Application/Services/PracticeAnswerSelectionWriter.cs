using CraftQuest.Domain.Entities;

namespace CraftQuest.Application.Services;

public static class PracticeAnswerSelectionWriter
{
    /// <summary>
    /// Replaces the stored selection for a question snapshot (never accumulates).
    /// For single-choice types, only the last submitted id is kept.
    /// </summary>
    public static IReadOnlyList<Guid> NormalizeSelectedIds(
        IReadOnlyList<Guid>? selectedIds,
        bool supportsMultipleCorrectAnswers)
    {
        var normalized = selectedIds?.Distinct().ToList() ?? [];
        if (normalized.Count == 0)
        {
            return normalized;
        }

        if (!supportsMultipleCorrectAnswers && normalized.Count > 1)
        {
            return [normalized[^1]];
        }

        return normalized;
    }

    public static void ApplySelection(
        PracticeQuestionSnapshot questionSnapshot,
        IReadOnlyList<Guid> selectedIds,
        bool supportsMultipleCorrectAnswers,
        DateTime selectedAt)
    {
        var normalized = NormalizeSelectedIds(selectedIds, supportsMultipleCorrectAnswers);
        var selectedSet = normalized.ToHashSet();

        foreach (var answer in questionSnapshot.AnswerOptionSnapshots)
        {
            var selected = selectedSet.Contains(answer.AnswerOptionId);
            answer.WasSelected = selected;
            answer.SelectedAt = selected ? selectedAt : null;
        }
    }
}
