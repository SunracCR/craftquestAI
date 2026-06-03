namespace CraftQuest.Application.Services;

/// <summary>
/// Question/answer ordering for practice sessions (shared by API and unit tests).
/// </summary>
public static class PracticeSessionOrdering
{
    /// <summary>
    /// Free practice may override via request. Class assignments use the teacher's
    /// assignment setting unless the teacher allows the student to choose.
    /// </summary>
    public static bool ResolveRandomizeQuestions(
        bool hasAssignmentId,
        bool? requestRandomizeQuestions,
        bool quizRandomizeQuestions,
        bool assignmentRandomizeQuestions = false,
        bool allowStudentRandomizeQuestions = false) =>
        hasAssignmentId
            ? allowStudentRandomizeQuestions
                ? requestRandomizeQuestions ?? assignmentRandomizeQuestions
                : assignmentRandomizeQuestions
            : requestRandomizeQuestions ?? quizRandomizeQuestions;

    public static List<T> OrderQuestions<T>(
        IReadOnlyList<T> questions,
        bool randomize,
        Random? random = null)
    {
        if (questions.Count <= 1 || !randomize)
        {
            return questions.ToList();
        }

        var rng = random ?? Random.Shared;
        return questions.OrderBy(_ => rng.Next()).ToList();
    }

    public static List<T> ShuffleAnswerOptions<T>(IReadOnlyList<T> options, string seed)
    {
        var list = options.ToList();
        if (list.Count <= 1)
        {
            return list;
        }

        var random = new Random(HashCode.Combine(seed.GetHashCode()));
        for (var i = list.Count - 1; i > 0; i--)
        {
            var j = random.Next(i + 1);
            (list[i], list[j]) = (list[j], list[i]);
        }

        return list;
    }
}
