using System.Text.Json;
using CraftQuest.Api.Extensions;
using CraftQuest.Api.Middleware;
using CraftQuest.Api.Serialization;
using CraftQuest.Application.Options;
using CraftQuest.Infrastructure;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.Ai;
using Microsoft.Extensions.Options;

var builder = WebApplication.CreateBuilder(args);

if (builder.Environment.IsDevelopment())
{
    builder.Logging.AddFilter("Microsoft.Extensions.Logging.EventLog.EventLogLoggerProvider", LogLevel.None);

    builder.Configuration.AddJsonFile(
        "appsettings.Development.local.json",
        optional: true,
        reloadOnChange: true);
}

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
        options.JsonSerializerOptions.Converters.Add(new UtcDateTimeJsonConverter());
        options.JsonSerializerOptions.Converters.Add(new NullableUtcDateTimeJsonConverter());
    });
builder.Services.AddCraftQuestApplicationInsights(builder.Configuration);
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddCraftQuestAuth(builder.Configuration);
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var healthChecks = builder.Services.AddHealthChecks()
    .AddCheck("self", () => Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Healthy(), tags: ["live"]);
if (!builder.Environment.IsEnvironment("Testing"))
{
    healthChecks.AddDbContextCheck<CraftQuestDbContext>("database", tags: ["ready"]);
}

builder.Services.Configure<CorsOptions>(builder.Configuration.GetSection(CorsOptions.SectionName));

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowMyApp", policy =>
    {
        if (builder.Environment.IsDevelopment())
        {
            policy.SetIsOriginAllowed(_ => true)
                .AllowAnyHeader()
                .AllowAnyMethod()
                .AllowCredentials();
            return;
        }

        var configuredOrigins = builder.Configuration
            .GetSection(CorsOptions.SectionName)
            .Get<CorsOptions>()?.AllowedOrigins ?? [];

        var allowedOrigins = configuredOrigins
            .Where(static o => !string.IsNullOrWhiteSpace(o))
            .Append("https://app.craftquestai.com")
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();

        policy.WithOrigins(allowedOrigins)
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
    });
});

var app = builder.Build();

app.UseHttpsRedirection();

if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
}

app.UseMiddleware<ExceptionHandlingMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseRouting();
app.UseCors("AllowMyApp");
app.UseAuthentication();
app.UseAuthorization();
app.UseMiddleware<UserContextTelemetryMiddleware>();
app.UseStaticFiles();
app.MapControllers().RequireCors("AllowMyApp");
app.MapGet("/", () => Results.Ok());
app.MapHealthChecks("/healthz");
app.MapHealthChecks("/health/live", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("live"),
}).RequireCors("AllowMyApp");
app.MapHealthChecks("/health", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready"),
}).RequireCors("AllowMyApp");

if (app.Environment.IsDevelopment())
{
    var genOpts = app.Services.GetRequiredService<IOptions<AiGenerationOptions>>().Value;
    if (genOpts.EnableAiGenerationTraceLogging)
    {
        var env = app.Services.GetRequiredService<IHostEnvironment>();
        var traceDir = AiGenerationTraceContext.GetTraceDirectory(
            app.Services.GetRequiredService<IOptions<AiGenerationOptions>>(),
            env);
        Directory.CreateDirectory(traceDir);
        var logger = app.Services.GetRequiredService<ILoggerFactory>().CreateLogger("AiGenTrace");
        logger.LogWarning(
            "AI generation trace ENABLED. Log files: {TraceDirectory}\\{{jobId}}.log (job id without dashes)",
            traceDir);
    }
}

app.Run();
