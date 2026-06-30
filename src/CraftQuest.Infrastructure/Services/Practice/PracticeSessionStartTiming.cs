using System.Diagnostics;
using Microsoft.Extensions.Logging;

namespace CraftQuest.Infrastructure.Services.Practice;

internal sealed class PracticeSessionStartTiming(ILogger logger, bool enabled)
{
    private readonly Stopwatch _total = Stopwatch.StartNew();
    private readonly List<(string Phase, long Milliseconds)> _phases = [];

    public PhaseScope Phase(string phaseName) => new(this, phaseName);

    public void LogSummary(Guid quizId, int questionCount, int optionCount)
    {
        if (!enabled)
        {
            return;
        }

        var phaseSummary = string.Join(
            ", ",
            _phases.Select(p => $"{p.Phase}={p.Milliseconds}ms"));

        logger.LogInformation(
            "Practice session start completed quizId={QuizId} questions={QuestionCount} options={OptionCount} totalMs={TotalMs} phases=[{Phases}]",
            quizId,
            questionCount,
            optionCount,
            _total.ElapsedMilliseconds,
            phaseSummary);
    }

    internal sealed class PhaseScope(PracticeSessionStartTiming parent, string phaseName) : IDisposable
    {
        private readonly Stopwatch _stopwatch = Stopwatch.StartNew();

        public void Dispose()
        {
            _stopwatch.Stop();
            parent._phases.Add((phaseName, _stopwatch.ElapsedMilliseconds));
        }
    }
}
