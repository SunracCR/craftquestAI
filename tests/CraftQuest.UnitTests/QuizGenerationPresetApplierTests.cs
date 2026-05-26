using CraftQuest.Application.Models.StudyMaterials;
using CraftQuest.Application.Services.StudyMaterials;

namespace CraftQuest.UnitTests;

public class QuizGenerationPresetApplierTests
{
    [Fact]
    public void Apply_QuickReview_SetsExpectedDefaults()
    {
        var parameters = new QuizGenerationParametersDto
        {
            QuestionCount = 0,
            Preset = "quick_review",
        };
        var result = QuizGenerationPresetApplier.Apply(parameters);

        Assert.Equal("quick_review", result.Preset);
        Assert.Equal(8, result.QuestionCount);
        Assert.Equal("easy", result.Difficulty);
        Assert.DoesNotContain(
            result.AllowedQuestionTypes,
            t => t.Contains("image", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void Apply_RemovesImageTypesFromCustomList()
    {
        var parameters = new QuizGenerationParametersDto
        {
            AllowedQuestionTypes = ["single_choice", "image_choice"],
        };

        var result = QuizGenerationPresetApplier.Apply(parameters);

        Assert.Equal(["single_choice"], result.AllowedQuestionTypes);
    }
}
