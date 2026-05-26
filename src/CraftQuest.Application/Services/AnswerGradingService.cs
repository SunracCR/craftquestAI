namespace CraftQuest.Application.Services;

public static class AnswerGradingService
{
    public static bool IsAnswerCorrect(
        IReadOnlySet<Guid> selectedIds,
        IReadOnlySet<Guid> correctIds,
        bool supportsMultipleCorrectAnswers)
    {
        if (selectedIds.Count == 0)
        {
            return false;
        }

        if (!supportsMultipleCorrectAnswers)
        {
            return selectedIds.Count == 1 && correctIds.Count == 1 && selectedIds.SetEquals(correctIds);
        }

        return selectedIds.SetEquals(correctIds);
    }

    public static IReadOnlyList<string> BuildDisplayLabels(int count)
    {
        if (count <= 0)
        {
            return [];
        }

        var labels = new List<string>(count);
        for (var i = 0; i < count; i++)
        {
            labels.Add(IndexToDisplayLabel(i));
        }

        return labels;
    }

    public static string IndexToDisplayLabel(int index)
    {
        if (index < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(index));
        }

        var label = string.Empty;
        var value = index;
        do
        {
            label = (char)('A' + (value % 26)) + label;
            value = (value / 26) - 1;
        }
        while (value >= 0);

        return label;
    }
}
