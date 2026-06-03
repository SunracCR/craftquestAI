using CraftQuest.Application.Services;

namespace CraftQuest.UnitTests;

/// <summary>TST-RND-001 / assignment randomization policy.</summary>
public class PracticeSessionOrderingTests
{
    [Fact]
    public void ShuffleAnswerOptions_TST_RND_001_SameSeedProducesSameOrder()
    {
        var options = Enumerable.Range(0, 4).Select(i => new SortableOption(i)).ToList();
        const string seed = "session-seed-abc";

        var first = PracticeSessionOrdering.ShuffleAnswerOptions(options, seed);
        var second = PracticeSessionOrdering.ShuffleAnswerOptions(options, seed);

        Assert.Equal(first.Select(o => o.Id), second.Select(o => o.Id));
    }

    [Fact]
    public void ShuffleAnswerOptions_TST_RND_001_CanPermuteWithSomeSeeds()
    {
        var options = Enumerable.Range(0, 4).Select(i => new SortableOption(i)).ToList();
        var originalOrder = options.Select(o => o.Id).ToList();

        var anyPermuted = Enumerable.Range(0, 32)
            .Select(i => PracticeSessionOrdering.ShuffleAnswerOptions(options, $"seed-{i}"))
            .Any(s => !s.Select(o => o.Id).SequenceEqual(originalOrder));

        Assert.True(anyPermuted);
    }

    [Fact]
    public void ShuffleAnswerOptions_SingleOption_Unchanged()
    {
        var options = new[] { new SortableOption(1) };
        var shuffled = PracticeSessionOrdering.ShuffleAnswerOptions(options, "any-seed");
        Assert.Single(shuffled);
        Assert.Equal(1, shuffled[0].Id);
    }

    [Fact]
    public void ResolveRandomizeQuestions_AssignmentLocked_UsesAssignmentSetting()
    {
        Assert.True(PracticeSessionOrdering.ResolveRandomizeQuestions(
            hasAssignmentId: true,
            requestRandomizeQuestions: false,
            quizRandomizeQuestions: false,
            assignmentRandomizeQuestions: true,
            allowStudentRandomizeQuestions: false));

        Assert.False(PracticeSessionOrdering.ResolveRandomizeQuestions(
            hasAssignmentId: true,
            requestRandomizeQuestions: true,
            quizRandomizeQuestions: true,
            assignmentRandomizeQuestions: false,
            allowStudentRandomizeQuestions: false));
    }

    [Fact]
    public void ResolveRandomizeQuestions_AssignmentStudentChoice_UsesRequestWhenProvided()
    {
        Assert.True(PracticeSessionOrdering.ResolveRandomizeQuestions(
            hasAssignmentId: true,
            requestRandomizeQuestions: true,
            quizRandomizeQuestions: false,
            assignmentRandomizeQuestions: false,
            allowStudentRandomizeQuestions: true));

        Assert.False(PracticeSessionOrdering.ResolveRandomizeQuestions(
            hasAssignmentId: true,
            requestRandomizeQuestions: false,
            quizRandomizeQuestions: true,
            assignmentRandomizeQuestions: true,
            allowStudentRandomizeQuestions: true));
    }

    [Fact]
    public void ResolveRandomizeQuestions_AssignmentStudentChoice_FallsBackToAssignment()
    {
        Assert.True(PracticeSessionOrdering.ResolveRandomizeQuestions(
            hasAssignmentId: true,
            requestRandomizeQuestions: null,
            quizRandomizeQuestions: false,
            assignmentRandomizeQuestions: true,
            allowStudentRandomizeQuestions: true));

        Assert.False(PracticeSessionOrdering.ResolveRandomizeQuestions(
            hasAssignmentId: true,
            requestRandomizeQuestions: null,
            quizRandomizeQuestions: true,
            assignmentRandomizeQuestions: false,
            allowStudentRandomizeQuestions: true));
    }

    [Fact]
    public void ResolveRandomizeQuestions_FreePractice_UsesRequestWhenProvided()
    {
        Assert.True(PracticeSessionOrdering.ResolveRandomizeQuestions(false, true, false));
        Assert.False(PracticeSessionOrdering.ResolveRandomizeQuestions(false, false, true));
    }

    [Fact]
    public void ResolveRandomizeQuestions_FreePractice_FallsBackToQuiz()
    {
        Assert.True(PracticeSessionOrdering.ResolveRandomizeQuestions(false, null, true));
        Assert.False(PracticeSessionOrdering.ResolveRandomizeQuestions(false, null, false));
    }

    [Fact]
    public void OrderQuestions_WhenRandomize_ReordersWithInjectedRandom()
    {
        var questions = new[] { "a", "b", "c", "d" };
        var random = new Random(42);

        var ordered = PracticeSessionOrdering.OrderQuestions(questions, randomize: true, random);

        Assert.Equal(questions.Length, ordered.Count);
        Assert.Equal(questions.OrderBy(x => x), ordered.OrderBy(x => x));
        Assert.NotEqual(questions, ordered);
    }

    private sealed record SortableOption(int Id);
}
