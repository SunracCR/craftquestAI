using CraftQuest.Application.Contracts;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace CraftQuest.Infrastructure.HostedServices;

public class AiProcessingHostedService(
    IServiceScopeFactory scopeFactory,
    ILogger<AiProcessingHostedService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
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
                await Task.Delay(TimeSpan.FromSeconds(2), stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
        }
    }
}
