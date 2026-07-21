using CraftQuest.Application;
using CraftQuest.Application.Contracts;

namespace CraftQuest.Infrastructure.Services.Ai;

/// <summary>
/// Slowly increments job progress while a long-running Gemini call is in flight.
/// Explicit milestone updates should call <see cref="BumpTo"/> to stay ahead of the heartbeat.
/// </summary>
internal sealed class AiGenerationProgressHeartbeat : IAsyncDisposable
{
    private readonly IAiGenerationJobProgress _progress;
    private readonly CancellationTokenSource _stopCts = new();
    private readonly Task _loop;
    private volatile int _current;
    private volatile int _ceiling;

    private AiGenerationProgressHeartbeat(
        IAiGenerationJobProgress progress,
        int floorPercent,
        int ceilingPercent,
        CancellationToken cancellationToken)
    {
        _progress = progress;
        _current = floorPercent;
        _ceiling = Math.Max(floorPercent + 1, ceilingPercent);
        _loop = RunAsync(cancellationToken);
    }

    public static AiGenerationProgressHeartbeat Start(
        IAiGenerationJobProgress progress,
        int floorPercent,
        int ceilingPercent,
        CancellationToken cancellationToken) =>
        new(progress, floorPercent, ceilingPercent, cancellationToken);

    public void BumpTo(int percent)
    {
        _current = Math.Max(_current, percent);
    }

    private async Task RunAsync(CancellationToken cancellationToken)
    {
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, _stopCts.Token);
        try
        {
            while (!linked.Token.IsCancellationRequested)
            {
                await Task.Delay(3000, linked.Token);
                var next = _current + 1;
                if (next >= _ceiling)
                {
                    continue;
                }

                _current = next;
                await _progress.UpdateAsync(AiJobStages.Generating, _current, linked.Token);
            }
        }
        catch (OperationCanceledException)
        {
            // Expected when generation completes or caller cancels.
        }
    }

    public async ValueTask DisposeAsync()
    {
        await _stopCts.CancelAsync();
        try
        {
            await _loop.ConfigureAwait(false);
        }
        catch (OperationCanceledException)
        {
            // Expected.
        }

        _stopCts.Dispose();
    }
}
