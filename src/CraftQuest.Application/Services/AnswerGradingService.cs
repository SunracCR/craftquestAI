namespace CraftQuest.Application.Services;

public readonly record struct AnswerGradingResult(bool IsFullyCorrect, decimal PointsAwarded);

public static class AnswerGradingService
{
    public const string PartialScoringPolicy = "partial_future";

    public static AnswerGradingResult GradeAnswer(
        IReadOnlySet<Guid> selectedIds,
        IReadOnlySet<Guid> correctIds,
        bool supportsMultipleCorrectAnswers,
        string scoringPolicy,
        decimal pointsPossible)
    {
        if (supportsMultipleCorrectAnswers && UsesPartialScoring(scoringPolicy))
        {
            return GradePartialMultiple(selectedIds, correctIds, pointsPossible);
        }

        var isCorrect = IsAnswerCorrect(selectedIds, correctIds, supportsMultipleCorrectAnswers);
        return new AnswerGradingResult(isCorrect, isCorrect ? pointsPossible : 0);
    }

    public static bool UsesPartialScoring(string scoringPolicy) =>
        string.Equals(scoringPolicy, PartialScoringPolicy, StringComparison.OrdinalIgnoreCase);

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

    private static AnswerGradingResult GradePartialMultiple(
        IReadOnlySet<Guid> selectedIds,
        IReadOnlySet<Guid> correctIds,
        decimal pointsPossible)
    {
        if (correctIds.Count == 0 || selectedIds.Count == 0)
        {
            return new AnswerGradingResult(false, 0);
        }

        var correctSelected = selectedIds.Count(correctIds.Contains);
        var wrongSelected = selectedIds.Count(id => !correctIds.Contains(id));
        var pointsPerCorrect = pointsPossible / correctIds.Count;
        var raw = (correctSelected * pointsPerCorrect) - (wrongSelected * pointsPerCorrect);
        var awarded = Math.Clamp(
            Math.Round(raw, 2, MidpointRounding.AwayFromZero),
            0,
            pointsPossible);

        var fullyCorrect = selectedIds.SetEquals(correctIds);
        return new AnswerGradingResult(fullyCorrect, awarded);
    }

    public static string ResolveScoringPolicyForQuestionType(string questionTypeCode, string? requestedPolicy)
    {
        if (string.Equals(questionTypeCode, "multiple_choice", StringComparison.OrdinalIgnoreCase))
        {
            return PartialScoringPolicy;
        }

        return string.IsNullOrWhiteSpace(requestedPolicy) ? "strict" : requestedPolicy.Trim();
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
