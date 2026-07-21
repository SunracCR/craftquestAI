using CraftQuest.Application.Options;
using CraftQuest.Application.Services.StudyMaterials;

namespace CraftQuest.UnitTests.Ai;

public class QuizGenerationCapacityCalculatorTests
{
    private static AiGenerationOptions DefaultOptions() => new()
    {
        MaxQuestionsPerGeneration = 100,
        MinQuestionsPerGeneration = 5,
        WordsPerQuestion = 100,
        MinQuestionsPerPage = 2,
        MaxQuestionsPerChunk = 18,
        RecommendedWordsPerQuestion = 150,
        ChunkTargetWordsPerRequest = 3800,
    };

    [Fact]
    public void ComputeMaterialCapacity_LowWordsHighPages_UsesPageCap()
    {
        var result = QuizGenerationCapacityCalculator.ComputeMaterialCapacity(
            words: 180,
            pageCount: 12,
            DefaultOptions());

        Assert.Equal(5, result.WordCap);
        Assert.Equal(24, result.PageCap);
        Assert.Equal(24, result.MaterialCap);
    }

    [Fact]
    public void ComputeMaterialCapacity_ShortDenseDocument_UsesWordCap()
    {
        var result = QuizGenerationCapacityCalculator.ComputeMaterialCapacity(
            words: 600,
            pageCount: 4,
            DefaultOptions());

        Assert.Equal(6, result.WordCap);
        Assert.Equal(8, result.PageCap);
        Assert.Equal(8, result.MaterialCap);
    }

    [Fact]
    public void ComputeMaterialCapacity_LargeDocument_HitsGlobalCap()
    {
        var result = QuizGenerationCapacityCalculator.ComputeMaterialCapacity(
            words: 30_000,
            pageCount: 120,
            DefaultOptions());

        Assert.Equal(100, result.MaterialCap);
    }

    [Fact]
    public void ComputeMaxSelectable_TakesMinimumOfLayers()
    {
        var max = QuizGenerationCapacityCalculator.ComputeMaxSelectable(
            materialCap: 40,
            planGenerationCap: 25,
            quizSlotCap: 50);

        Assert.Equal(25, max);
    }

    [Fact]
    public void ComputeJobTimeoutMinutes_ScalesWithChunks()
    {
        var options = DefaultOptions();
        options.GenerationJobTimeoutMinutes = 15;
        options.GenerationJobTimeoutBaseMinutes = 8;
        options.GenerationJobTimeoutMinutesPerChunk = 2;
        options.GenerationJobTimeoutMaxMinutes = 25;

        var timeout = QuizGenerationCapacityCalculator.ComputeJobTimeoutMinutes(20_000, options);

        Assert.InRange(timeout, 15, 25);
    }
}
