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

var healthChecks = builder.Services.AddHealthChecks();
if (!builder.Environment.IsEnvironment("Testing"))
{
    healthChecks.AddDbContextCheck<CraftQuestDbContext>("database");
}

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowMyApp", policy =>
    {
        policy.WithOrigins("https://app.craftquestai.com")
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
app.MapControllers();
app.MapHealthChecks("/health");

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
