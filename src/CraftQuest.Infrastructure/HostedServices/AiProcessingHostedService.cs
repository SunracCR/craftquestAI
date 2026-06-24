using CraftQuest.Application.Contracts;
using CraftQuest.Application.Options;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.HostedServices;

public class AiProcessingHostedService(
    IServiceScopeFactory scopeFactory,
    IOptions<AiGenerationOptions> generationOptions,
    ILogger<AiProcessingHostedService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var loopDelayMs = Math.Clamp(generationOptions.Value.ProcessingLoopDelayMilliseconds, 250, 5000);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = scopeFactory.CreateScope();
                var studyMaterials = scope.ServiceProvider.GetRequiredService<IStudyMaterialService>();
                var quizGeneration = scope.ServiceProvider.GetRequiredService<IQuizGenerationService>();

                await studyMaterials.ProcessPendingExtractionsAsync(stoppingToken);
                await quizGeneration.ProcessPendingGenerationJobsAsync(stoppingToken);
                await studyMaterials.ProcessExpiredMaterialsAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "AI processing loop failed.");
            }

            try
            {
                await Task.Delay(TimeSpan.FromMilliseconds(loopDelayMs), stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
        }
    }
}
