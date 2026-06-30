using System.Threading.Channels;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace CraftQuest.Infrastructure.Services.Practice;

public interface IPracticeSnapshotDeferredWriter
{
    void EnqueueRemainingAnswerOptions(
        Guid practiceSessionId,
        IReadOnlyList<PracticeAnswerOptionSnapshot> answerOptions);
}

internal sealed class PracticeSnapshotDeferredWriter(
    Channel<DeferredAnswerOptionsWorkItem> channel) : IPracticeSnapshotDeferredWriter
{
    public void EnqueueRemainingAnswerOptions(
        Guid practiceSessionId,
        IReadOnlyList<PracticeAnswerOptionSnapshot> answerOptions)
    {
        if (answerOptions.Count == 0)
        {
            return;
        }

        channel.Writer.TryWrite(new DeferredAnswerOptionsWorkItem(
            practiceSessionId,
            answerOptions.ToList()));
    }
}

internal sealed record DeferredAnswerOptionsWorkItem(
    Guid PracticeSessionId,
    IReadOnlyList<PracticeAnswerOptionSnapshot> AnswerOptions);

internal sealed class PracticeSnapshotDeferredWriterHostedService(
    Channel<DeferredAnswerOptionsWorkItem> channel,
    IServiceScopeFactory scopeFactory,
    ILogger<PracticeSnapshotDeferredWriterHostedService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("Practice snapshot deferred writer started.");

        await foreach (var workItem in channel.Reader.ReadAllAsync(stoppingToken))
        {
            try
            {
                using var scope = scopeFactory.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<CraftQuestDbContext>();

                await PracticeSnapshotBulkInserter.InsertAnswerOptionsAsync(
                    dbContext,
                    workItem.AnswerOptions,
                    stoppingToken);

                logger.LogDebug(
                    "Deferred answer-option insert completed sessionId={SessionId} count={Count}",
                    workItem.PracticeSessionId,
                    workItem.AnswerOptions.Count);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogError(
                    ex,
                    "Deferred answer-option insert failed sessionId={SessionId} count={Count}",
                    workItem.PracticeSessionId,
                    workItem.AnswerOptions.Count);
            }
        }
    }
}

internal static class PracticeSnapshotDeferredWriterRegistration
{
    public static IServiceCollection AddPracticeSnapshotDeferredWriter(this IServiceCollection services)
    {
        services.AddSingleton(_ => Channel.CreateUnbounded<DeferredAnswerOptionsWorkItem>(
            new UnboundedChannelOptions
            {
                SingleReader = true,
                SingleWriter = false,
            }));

        services.AddSingleton<IPracticeSnapshotDeferredWriter, PracticeSnapshotDeferredWriter>();
        services.AddHostedService<PracticeSnapshotDeferredWriterHostedService>();

        return services;
    }
}
