using System.Diagnostics;
using Microsoft.Extensions.Logging;

namespace CraftQuest.Infrastructure.Services.PrepPlus;

internal sealed class PrepPlusQueryTiming(ILogger logger, bool enabled)
{
    private readonly Stopwatch _total = Stopwatch.StartNew();
    private readonly List<(string Phase, long Milliseconds)> _phases = [];

    public PhaseScope Phase(string phaseName) => new(this, phaseName);

    public void LogSummary(string operation, string? detail = null)
    {
        if (!enabled)
        {
            return;
        }

        var phaseSummary = string.Join(
            ", ",
            _phases.Select(p => $"{p.Phase}={p.Milliseconds}ms"));

        logger.LogInformation(
            "Prep+ query completed operation={Operation} detail={Detail} totalMs={TotalMs} phases=[{Phases}]",
            operation,
            detail ?? string.Empty,
            _total.ElapsedMilliseconds,
            phaseSummary);
    }

    internal sealed class PhaseScope(PrepPlusQueryTiming parent, string phaseName) : IDisposable
    {
        private readonly Stopwatch _stopwatch = Stopwatch.StartNew();

        public void Dispose()
        {
            _stopwatch.Stop();
            parent._phases.Add((phaseName, _stopwatch.ElapsedMilliseconds));
        }
    }
}
