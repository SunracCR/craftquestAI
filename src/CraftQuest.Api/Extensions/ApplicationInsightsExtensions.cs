using CraftQuest.Api.Telemetry;
using OpenTelemetry.Instrumentation.AspNetCore;
using OpenTelemetry.Trace;

namespace CraftQuest.Api.Extensions;

public static class ApplicationInsightsExtensions
{
    public static IServiceCollection AddCraftQuestApplicationInsights(
        this IServiceCollection services,
        IConfiguration configuration,
        IHostEnvironment environment)
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
            options.EnableQuickPulseMetricStream = false;

            if (!environment.IsDevelopment())
            {
                // SDK 3.x: rate-limited sampling (reemplaza adaptive sampling de 2.x).
                options.TracesPerSecond = 5;
            }
        });

        if (!environment.IsDevelopment())
        {
            services.Configure<AspNetCoreTraceInstrumentationOptions>(options =>
            {
                options.Filter = httpContext => !IsNoisePath(httpContext.Request.Path);
            });

            services.ConfigureOpenTelemetryTracerProvider((_, tracerBuilder) =>
            {
                tracerBuilder.AddProcessor(new HealthCheckActivityProcessor());
            });
        }

        return services;
    }

    public static ILoggingBuilder AddCraftQuestApplicationInsightsLogging(
        this ILoggingBuilder logging,
        IHostEnvironment environment)
    {
        if (!environment.IsDevelopment())
        {
            logging.SetMinimumLevel(LogLevel.Warning);
        }

        return logging;
    }

    private static bool IsNoisePath(PathString path)
    {
        if (!path.HasValue)
        {
            return false;
        }

        var value = path.Value!;
        return value.Equals("/", StringComparison.OrdinalIgnoreCase)
            || value.StartsWith("/health", StringComparison.OrdinalIgnoreCase);
    }
}
