using System.Text;
using System.Text.Json;
using CraftQuest.Application.Models.Imports;
using CraftQuest.Application.Options;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Ai;

/// <summary>
/// Temporary diagnostic trace for AI quiz generation. Remove when stable.
/// Logs to ILogger and to logs/ai-gen-trace/{jobId}.log under ContentRoot.
/// </summary>
public sealed class AiGenerationTraceContext(
    IOptions<AiGenerationOptions> options,
    ILogger<AiGenerationTraceContext> logger,
    IHostEnvironment hostEnvironment)
{
    private static readonly JsonSerializerOptions JsonOptions = new() { WriteIndented = false };

    private Guid? _jobId;
    private StreamWriter? _fileWriter;
    private bool _enabled;
    private int _cqifRepairCount;

    public bool IsActive => _enabled && _jobId is not null;

    public int CqifRepairCount => _cqifRepairCount;

    public void BeginJob(Guid jobId)
    {
        EndJob();
        _cqifRepairCount = 0;
        _jobId = jobId;
        _enabled = options.Value.EnableAiGenerationTraceLogging;
        if (!_enabled)
        {
            return;
        }
        try
        {
            var dir = ResolveLogDirectory();
            Directory.CreateDirectory(dir);
            var path = Path.Combine(dir, $"{jobId:N}.log");
            _fileWriter = new StreamWriter(path, append: false, Encoding.UTF8) { AutoFlush = true };
            WriteLine("=== AI generation trace started ===");
            WriteLine($"Utc: {DateTime.UtcNow:O}");
            WriteLine($"Log file: {path}");
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "[AiGenTrace] Could not create trace file for job {JobId}", jobId);
            _fileWriter = null;
        }

        var logPath = _fileWriter is not null
            ? Path.Combine(ResolveLogDirectory(), $"{jobId:N}.log")
            : null;

        logger.LogWarning(
            "[AiGenTrace] Job {JobId} — trace file: {TraceFilePath}",
            jobId,
            logPath ?? "(file not created; see console warnings)");
    }

    public static string GetTraceDirectory(IOptions<AiGenerationOptions> opts, IHostEnvironment env)
    {
        var configured = opts.Value.TraceLogDirectory;
        return Path.IsPathRooted(configured)
            ? configured
            : Path.Combine(env.ContentRootPath, configured);
    }

    public void EndJob()
    {
        if (_fileWriter is not null)
        {
            WriteLine("=== AI generation trace ended ===");
            _fileWriter.Dispose();
            _fileWriter = null;
        }

        if (_jobId is not null)
        {
            if (_cqifRepairCount > 0)
            {
                logger.LogWarning(
                    "[AiGen] JobId={JobId} completed with {RepairCount} CQIF JSON repair(s)",
                    _jobId,
                    _cqifRepairCount);
            }

            logger.LogInformation("[AiGenTrace] JobId={JobId} END trace", _jobId);
        }

        _jobId = null;
        _enabled = false;
    }

    public void RecordCqifRepair(string label)
    {
        var count = Interlocked.Increment(ref _cqifRepairCount);
        logger.LogWarning(
            "[AiGen] JobId={JobId} CQIF parse failed for {Label}; repair invoked (total repairs={Count})",
            _jobId,
            label,
            count);
    }

    public void Stage(string stage, string message, object? data = null)
    {
        if (!IsActive)
        {
            return;
        }

        var dataSuffix = data is null ? string.Empty : $" | {SerializeData(data)}";
        var line = $"[{stage}] {message}{dataSuffix}";
        WriteLine(line);
        logger.LogInformation("[AiGenTrace] JobId={JobId} Stage={Stage} {Message} {Data}", _jobId, stage, message, data);
    }

    public void Prompt(string label, string prompt)
    {
        if (!IsActive)
        {
            return;
        }

        var max = Math.Max(500, options.Value.TraceMaxLoggedCharacters);
        var excerpt = Truncate(prompt, max);
        WriteLine($"--- PROMPT: {label} (len={prompt.Length}) ---");
        WriteLine(excerpt);
        if (prompt.Length > max)
        {
            WriteLine($"... [truncated {prompt.Length - max} chars] ...");
        }

        logger.LogInformation(
            "[AiGenTrace] JobId={JobId} Prompt={Label} Length={Length}",
            _jobId,
            label,
            prompt.Length);
    }

    public void GeminiResponse(
        string label,
        string model,
        string rawText,
        int? parsedQuestionCount = null,
        string? parseNote = null)
    {
        if (!IsActive)
        {
            return;
        }

        var max = Math.Max(500, options.Value.TraceMaxLoggedCharacters);
        WriteLine($"--- GEMINI RESPONSE: {label} model={model} len={rawText.Length} parsedQuestions={parsedQuestionCount?.ToString() ?? "n/a"} ---");
        if (!string.IsNullOrWhiteSpace(parseNote))
        {
            WriteLine($"Parse: {parseNote}");
        }

        WriteLine(Truncate(rawText, max));
        if (rawText.Length > max)
        {
            WriteLine($"... [truncated {rawText.Length - max} chars] ...");
        }

        logger.LogInformation(
            "[AiGenTrace] JobId={JobId} Response={Label} Model={Model} Length={Length} ParsedQuestions={Count} Note={Note}",
            _jobId,
            label,
            model,
            rawText.Length,
            parsedQuestionCount,
            parseNote);
    }

    public void DocumentSnapshot(string label, CqifDocument document)
    {
        if (!IsActive)
        {
            return;
        }

        var typeCounts = document.Questions
            .GroupBy(q => q.Type ?? "(null)")
            .ToDictionary(g => g.Key, g => g.Count());

        Stage(label, "CQIF document snapshot", new
        {
            cqifVersion = document.CqifVersion,
            questionCount = document.Questions.Count,
            types = typeCounts,
            sampleTexts = document.Questions.Take(3).Select(q => Truncate(q.Text ?? "", 80)).ToList(),
        });
    }

    public void ImportBatchSnapshot(
        string label,
        int totalRows,
        int validRows,
        int errorRows,
        string batchStatus,
        IReadOnlyList<(int Row, string Status, string? ErrorCode, string? Message)> rowSamples)
    {
        if (!IsActive)
        {
            return;
        }

        var rows = rowSamples
            .Take(10)
            .Select(r => new
            {
                r.Row,
                r.Status,
                r.ErrorCode,
                message = r.Message is { Length: > 120 } m ? m[..120] + "…" : r.Message,
            })
            .ToList();

        Stage(label, "Import batch snapshot", new
        {
            totalRows,
            validRows,
            errorRows,
            batchStatus,
            rows,
        });
    }

    private string ResolveLogDirectory() =>
        GetTraceDirectory(options, hostEnvironment);

    private void WriteLine(string line)
    {
        _fileWriter?.WriteLine(line);
    }

    private static string Truncate(string value, int max) =>
        value.Length <= max ? value : value[..max];

    private static string SerializeData(object data)
    {
        try
        {
            return JsonSerializer.Serialize(data, JsonOptions);
        }
        catch
        {
            return data.ToString() ?? string.Empty;
        }
    }
}
