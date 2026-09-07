namespace CraftQuest.Infrastructure.Services.Ai;

/// <summary>
/// Rules for auto-importing AI-generated questions before marking the job completed.
/// </summary>
public static class AiGenerationAutoImportRules
{
    public static bool ShouldFailBeforeConfirm(int validQuestions) => validQuestions <= 0;

    public static bool ShouldFailAfterConfirm(int createdQuestions) => createdQuestions <= 0;
}
