using System.Text;
using CraftQuest.Application;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Imports;
using CraftQuest.Application.Models.StudyMaterials;
using CraftQuest.Application.Options;
using CraftQuest.Application.Services.Imports;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Ai;

public class GeminiQuizGenerationProvider(
    GeminiContentClient geminiClient,
    IOptions<AiOptions> aiOptions,
    IOptions<AiGenerationOptions> generationOptions,
    AiGenerationTraceContext trace,
    IAiGenerationJobProgress jobProgress) : IQuizGenerationProvider
{
    private const string RepairSchemaHint = """
        {
          "cqifVersion": "2.0",
          "quiz": { "title": "string" },
          "questions": [
            {
              "type": "single_choice",
              "text": "string",
              "answerOptions": [{ "key": "a", "text": "string" }],
              "correctAnswerKeys": ["a"]
            }
          ]
        }
        """;

    public string ProviderName => "gemini";

    public async Task<CqifDocument> GenerateAsync(
        string sourceText,
        QuizGenerationParametersDto parameters,
        CancellationToken cancellationToken = default)
    {
        var options = aiOptions.Value;
        var genOptions = generationOptions.Value;

        if (string.IsNullOrWhiteSpace(options.GeminiApiKey))
        {
            throw new AppException("Gemini API key is not configured.", 503);
        }

        if (sourceText.Length > options.MaxInputCharacters)
        {
            throw new AppException(
                $"Source text exceeds maximum length ({options.MaxInputCharacters} characters).",
                400,
                "GENERATION_SCOPE_TOO_LARGE");
        }

        var chunks = StudyMaterialTextChunker.SplitIntoChunks(
            sourceText,
            genOptions.ChunkTargetWordsPerRequest);

        await jobProgress.UpdateAsync(AiJobStages.Preparing, 10, cancellationToken);

        trace.Stage("provider.start", "GenerateAsync", new
        {
            sourceChars = sourceText.Length,
            chunkCount = chunks.Count,
            requestedQuestions = parameters.QuestionCount,
            allowedTypes = parameters.AllowedQuestionTypes,
            pages = $"{parameters.PageFrom}-{parameters.PageTo}",
            language = parameters.Language,
        });

        await jobProgress.UpdateAsync(AiJobStages.Outlining, 15, cancellationToken);
        var outline = await TryBuildOutlineAsync(
            sourceText,
            chunks.Count,
            parameters,
            genOptions,
            cancellationToken);

        if (chunks.Count == 1)
        {
            var outlineItems = outline?.Items.ToList();
            return await GenerateSingleChunkAsync(
                chunks[0],
                parameters.QuestionCount,
                parameters,
                chunkIndex: 1,
                chunkTotal: 1,
                outlineItems,
                cancellationToken);
        }

        return await GenerateParallelChunksAsync(
            chunks,
            parameters,
            genOptions,
            outline,
            cancellationToken);
    }

    private async Task ReportChunkProgressAsync(int completed, int total, CancellationToken cancellationToken)
    {
        if (total <= 0)
        {
            return;
        }

        var percent = 20 + (int)Math.Round(50.0 * completed / total);
        await jobProgress.UpdateAsync(AiJobStages.Generating, percent, cancellationToken);
    }

    private async Task<QuizGenerationOutlinePlan?> TryBuildOutlineAsync(
        string sourceText,
        int chunkCount,
        QuizGenerationParametersDto parameters,
        AiGenerationOptions genOptions,
        CancellationToken cancellationToken)
    {
        if (!genOptions.UseOutlinePhase
            || parameters.QuestionCount < genOptions.MinQuestionsForOutlinePhase)
        {
            trace.Stage("outline.skip", "Outline phase disabled or below minimum questions");
            return null;
        }

        var excerpt = BuildOutlineSourceExcerpt(sourceText, genOptions.OutlineMaxSourceCharacters);
        var prompt = BuildOutlinePrompt(excerpt, parameters, parameters.QuestionCount, chunkCount);
        var outlineConfig = new { temperature = 0.15, responseMimeType = "application/json" };

        try
        {
            var model = string.IsNullOrWhiteSpace(genOptions.OutlineGeminiModel)
                ? aiOptions.Value.GeminiFallbackModels.FirstOrDefault() ?? aiOptions.Value.GeminiModel
                : genOptions.OutlineGeminiModel;

            trace.Prompt("outline", prompt);
            var json = await geminiClient.GenerateTextWithModelAsync(
                model,
                prompt,
                outlineConfig,
                "Gemini quiz outline",
                cancellationToken);

            var plan = QuizGenerationOutlineParser.Parse(json, parameters.QuestionCount, chunkCount);
            trace.GeminiResponse("outline", model, json, plan.Items.Count, "outline parsed");
            trace.Stage("outline.ok", "Outline plan ready", new { itemCount = plan.Items.Count });
            return plan;
        }
        catch (Exception ex)
        {
            trace.Stage("outline.failed", "Outline phase failed; continuing without plan", new { error = ex.Message });
            return null;
        }
    }

    private async Task<CqifDocument> GenerateParallelChunksAsync(
        IReadOnlyList<string> chunks,
        QuizGenerationParametersDto parameters,
        AiGenerationOptions genOptions,
        QuizGenerationOutlinePlan? outline,
        CancellationToken cancellationToken)
    {
        var questionCounts = StudyMaterialTextChunker.DistributeQuestionCounts(
            parameters.QuestionCount,
            chunks.Count);

        trace.Stage("chunks.parallel", "Starting parallel chunk generation", new
        {
            chunks = chunks.Count,
            questionsPerChunk = questionCounts,
            outlineItems = outline?.Items.Count ?? 0,
        });

        IReadOnlyList<IReadOnlyList<QuizGenerationOutlineItem>> outlineGroups =
            outline is null
                ? Enumerable.Range(0, chunks.Count).Select(_ => (IReadOnlyList<QuizGenerationOutlineItem>)[]).ToList()
                : QuizGenerationQuestionMerger.GroupOutlineByChunk(outline.Items, chunks.Count);

        var maxParallel = Math.Max(1, genOptions.MaxParallelChunkRequests);
        using var gate = new SemaphoreSlim(maxParallel, maxParallel);
        var generationConfig = new { temperature = 0.2, responseMimeType = "application/json" };
        var completedChunks = 0;

        await jobProgress.UpdateAsync(AiJobStages.Generating, 20, cancellationToken);

        var tasks = chunks.Select(async (chunkText, index) =>
        {
            await gate.WaitAsync(cancellationToken);
            try
            {
                var countForChunk = questionCounts[index];
                if (countForChunk <= 0)
                {
                    return new CqifDocument { CqifVersion = "2.0", Questions = [] };
                }

                var prompt = BuildPrompt(
                    chunkText,
                    parameters,
                    countForChunk,
                    chunkIndex: index + 1,
                    chunkTotal: chunks.Count,
                    outlineGroups[index].ToList());

                trace.Prompt($"chunk-{index + 1}", prompt);
                var result = await geminiClient.GenerateTextAsync(
                    prompt,
                    generationConfig,
                    $"Gemini quiz generation chunk {index + 1}/{chunks.Count}",
                    cancellationToken);

                var doc = await ParseOrRepairAsync(
                    result.Text,
                    result.Model,
                    $"chunk-{index + 1}",
                    cancellationToken);
                trace.DocumentSnapshot($"chunk-{index + 1}-parsed", doc);
                var done = Interlocked.Increment(ref completedChunks);
                await ReportChunkProgressAsync(done, chunks.Count, cancellationToken);
                return doc;
            }
            finally
            {
                gate.Release();
            }
        }).ToList();

        CqifDocument[] partials;
        try
        {
            partials = await Task.WhenAll(tasks);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            throw new AppException(
                "Parallel quiz generation failed for one or more source chunks. Please try again.",
                502,
                "AI_GENERATION_CHUNK_FAILED",
                new Dictionary<string, object?> { ["detail"] = ex.Message });
        }

        await jobProgress.UpdateAsync(AiJobStages.Merging, 78, cancellationToken);
        var merged = QuizGenerationQuestionMerger.Merge(
            partials,
            parameters.QuestionCount,
            genOptions.DeduplicateMergedQuestions);
        trace.DocumentSnapshot("merge.final", merged);
        return merged;
    }

    private async Task<CqifDocument> GenerateSingleChunkAsync(
        string chunkText,
        int questionCount,
        QuizGenerationParametersDto parameters,
        int chunkIndex,
        int chunkTotal,
        IReadOnlyList<QuizGenerationOutlineItem>? outlineItems,
        CancellationToken cancellationToken)
    {
        trace.Stage("chunk.single", "Single-chunk generation", new { questionCount, chunkIndex, chunkTotal });
        await jobProgress.UpdateAsync(AiJobStages.Generating, 25, cancellationToken);

        var prompt = BuildPrompt(
            chunkText,
            parameters,
            questionCount,
            chunkIndex,
            chunkTotal,
            outlineItems);
        var generationConfig = new { temperature = 0.2, responseMimeType = "application/json" };
        trace.Prompt("single-chunk", prompt);
        var result = await geminiClient.GenerateTextAsync(
            prompt,
            generationConfig,
            "Gemini quiz generation",
            cancellationToken);

        var document = await ParseOrRepairAsync(result.Text, result.Model, "single-chunk", cancellationToken);
        trace.DocumentSnapshot("single-chunk-parsed", document);
        var merged = QuizGenerationQuestionMerger.Merge(
            [document],
            questionCount,
            generationOptions.Value.DeduplicateMergedQuestions);
        trace.DocumentSnapshot("single-chunk-merged", merged);
        return merged;
    }

    private async Task<CqifDocument> ParseOrRepairAsync(
        string jsonText,
        string model,
        string label,
        CancellationToken cancellationToken)
    {
        try
        {
            var doc = CqifJsonParser.Parse(jsonText);
            trace.GeminiResponse(label, model, jsonText, doc.Questions.Count, "parsed OK");
            return doc;
        }
        catch (Exception ex)
        {
            trace.GeminiResponse(label, model, jsonText, null, $"parse failed: {ex.Message}");
            trace.RecordCqifRepair(label);
            trace.Stage("repair.start", $"Repairing CQIF for {label}");
            var repaired = await RepairCqifAsync(jsonText, model, label, cancellationToken);
            trace.DocumentSnapshot($"{label}-repaired", repaired);
            return repaired;
        }
    }

    private async Task<CqifDocument> RepairCqifAsync(
        string invalidJson,
        string model,
        string label,
        CancellationToken cancellationToken)
    {
        var repairPrompt = $"""
            Convert the following into valid CraftQuest CQIF JSON 2.0 only (no markdown).
            Root MUST be an object with cqifVersion, quiz, and questions array.
            correctAnswerKeys MUST be a JSON array of strings, never a single string.
            Schema example:
            {RepairSchemaHint}

            INPUT:
            {invalidJson}
            """;

        trace.Prompt($"{label}-repair", repairPrompt);
        var repaired = await geminiClient.GenerateTextWithModelAsync(
            model,
            repairPrompt,
            new { temperature = 0.1, responseMimeType = "application/json" },
            "Gemini quiz generation repair",
            cancellationToken);

        var doc = CqifJsonParser.Parse(repaired);
        trace.GeminiResponse($"{label}-repair", model, repaired, doc.Questions.Count, "repair parsed OK");
        return doc;
    }

    private static string BuildOutlineSourceExcerpt(string sourceText, int maxCharacters)
    {
        if (sourceText.Length <= maxCharacters)
        {
            return sourceText;
        }

        var builder = new StringBuilder();
        builder.AppendLine(sourceText.AsSpan(0, maxCharacters / 2).ToString());
        builder.AppendLine();
        builder.AppendLine("[... middle of source omitted for outline ...]");
        builder.AppendLine();
        builder.Append(sourceText.AsSpan(sourceText.Length - (maxCharacters / 2)).ToString());
        return builder.ToString();
    }

    private static string BuildOutlinePrompt(
        string sourceExcerpt,
        QuizGenerationParametersDto parameters,
        int questionCount,
        int chunkCount)
    {
        var types = string.Join(", ", parameters.AllowedQuestionTypes);
        const string outlineJsonExample =
            """{ "items": [ { "index": 1, "topic": "...", "suggestedType": "single_choice", "chunkIndex": 1 } ] }""";
        return $"""
            You are a curriculum planner for CraftQuest. Output JSON only (no markdown).
            Return shape (example): {outlineJsonExample}
            Rules:
            - Exactly {questionCount} items in "items".
            - chunkIndex must be between 1 and {chunkCount} (match --- Page N --- sections when present).
            - suggestedType must be one of: {types}.
            - Topics must be distinct and cover the material evenly.
            - Language for topic text: "{parameters.Language}".
            - Difficulty target: {parameters.Difficulty}.
            - Pedagogical goal: {parameters.PedagogicalGoal}.

            SOURCE EXCERPT:
            {sourceExcerpt}
            """;
    }

    private static string BuildPrompt(
        string sourceText,
        QuizGenerationParametersDto parameters,
        int questionCountForChunk,
        int chunkIndex,
        int chunkTotal,
        IReadOnlyList<QuizGenerationOutlineItem>? outlineItems)
    {
        var types = string.Join(", ", parameters.AllowedQuestionTypes);
        var topic = string.IsNullOrWhiteSpace(parameters.TopicFocus)
            ? "cover this source section evenly"
            : parameters.TopicFocus.Trim();
        var strict = parameters.StrictSourceOnly
            ? "Use ONLY facts explicitly present in SOURCE. Do not invent."
            : "Prefer SOURCE facts; minor inference allowed.";

        var chunkScope = chunkTotal > 1
            ? $"""
            This is SOURCE chunk {chunkIndex} of {chunkTotal}.
            Generate exactly {questionCountForChunk} questions using ONLY facts from this chunk.
            Do not duplicate questions that would belong to other parts of the material.
            """
            : $"Generate exactly {questionCountForChunk} questions in language \"{parameters.Language}\".";

        var outlineBlock = BuildOutlineInstructionsBlock(outlineItems);

        return $"""
            You are CraftQuest quiz generator. Output valid CQIF JSON 2.0 only (no markdown).
            Root object MUST include: cqifVersion, quiz, questions (array).
            cqifVersion must be "2.0".
            {chunkScope}
            {outlineBlock}
            Language for question text: "{parameters.Language}".
            Difficulty mode: {parameters.Difficulty}.
            Pedagogical goal: {parameters.PedagogicalGoal}.
            Allowed question types ONLY: {types}.
            NEVER use image_choice or image_based_question.
            Do not reference images, diagrams, or figures not described in text.
            Topic focus: {topic}.
            {strict}
            Each question needs: text, type, answerOptions (min 2) with unique key fields,
            correctAnswerKeys as JSON array referencing those keys (never a single string).
            For true_false use keys "true" and "false".
            Assign unique externalId per question (e.g. "q-1", "q-2").
            {(parameters.IncludeExplanations
                ? """
                  Each question MUST include a justification object:
                  - text: one paragraph explaining why the correct answer(s) are correct (cover all relevant options in this single text).
                  - visibility: "never" (review only; not shown during practice)
                  - sources: when SOURCE contains "--- Page N ---" markers, include at least one source per question with pageNumber (integer N) and snippet (short quote from that page). Use url "craftquest://source#page=N" when no external URL exists.
                  """
                : "Omit justification objects entirely.")}

            SOURCE:
            {sourceText}
            """;
    }

    private static string BuildOutlineInstructionsBlock(IReadOnlyList<QuizGenerationOutlineItem>? outlineItems)
    {
        if (outlineItems is null || outlineItems.Count == 0)
        {
            return string.Empty;
        }

        var lines = outlineItems
            .OrderBy(i => i.Index)
            .Select(i =>
            {
                var typeHint = string.IsNullOrWhiteSpace(i.SuggestedType) ? "any allowed" : i.SuggestedType;
                return $"- Q{i.Index}: {i.Topic} (prefer type: {typeHint})";
            });

        return $"""
            QUESTION PLAN (follow this order and focus; one question per line):
            {string.Join(Environment.NewLine, lines)}
            """;
    }
}
