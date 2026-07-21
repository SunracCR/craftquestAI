using CraftQuest.Application.Options;
using CraftQuest.Domain.Entities;

namespace CraftQuest.Application.Services.StudyMaterials;

public static class QuizGenerationCapacityCalculator
{
    public sealed record MaterialCapacity(
        int WordCap,
        int PageCap,
        int ChunkCap,
        int MaterialCap,
        int RecommendedQuestionCount);

    public static MaterialCapacity ComputeMaterialCapacity(
        int words,
        int pageCount,
        AiGenerationOptions options)
    {
        var min = options.MinQuestionsPerGeneration;
        var wordCap = Math.Max(
            min,
            (int)Math.Ceiling(words / (double)Math.Max(1, options.WordsPerQuestion)));
        var pageCap = pageCount > 0
            ? Math.Max(min, pageCount * options.MinQuestionsPerPage)
            : min;
        var chunkCount = Math.Max(
            1,
            (int)Math.Ceiling(words / (double)Math.Max(1, options.ChunkTargetWordsPerRequest)));
        var chunkCap = chunkCount * options.MaxQuestionsPerChunk;
        var contentCap = Math.Max(wordCap, Math.Max(pageCap, chunkCap));
        var materialCap = Math.Min(options.MaxQuestionsPerGeneration, contentCap);
        var recommended = Math.Min(
            materialCap,
            Math.Max(
                min,
                (int)Math.Ceiling(words / (double)Math.Max(1, options.RecommendedWordsPerQuestion))));

        return new MaterialCapacity(wordCap, pageCap, chunkCap, materialCap, recommended);
    }

    public static int ComputeMaxSelectable(
        int materialCap,
        int planGenerationCap,
        int quizSlotCap) =>
        Math.Min(materialCap, Math.Min(planGenerationCap, quizSlotCap));

    public static int ResolvePlanGenerationCap(Plan plan, AiGenerationOptions options) =>
        plan.MaxQuestionsPerAiGeneration ?? options.MaxQuestionsPerGeneration;

    public static int ComputeJobTimeoutMinutes(int words, AiGenerationOptions options)
    {
        var chunkCount = Math.Max(
            1,
            (int)Math.Ceiling(words / (double)Math.Max(1, options.ChunkTargetWordsPerRequest)));
        var dynamicTimeout = options.GenerationJobTimeoutBaseMinutes
            + chunkCount * options.GenerationJobTimeoutMinutesPerChunk;
        return Math.Clamp(
            dynamicTimeout,
            options.GenerationJobTimeoutMinutes,
            options.GenerationJobTimeoutMaxMinutes);
    }
}
