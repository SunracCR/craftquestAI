namespace CraftQuest.Api.Extensions;

public static class ApplicationInsightsExtensions
{
    public static IServiceCollection AddCraftQuestApplicationInsights(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"]
            ?? configuration["ApplicationInsights:ConnectionString"];

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            return services;
        }

        services.AddApplicationInsightsTelemetry(options =>
        {
            options.ConnectionString = connectionString;
        });

        return services;
    }
}
