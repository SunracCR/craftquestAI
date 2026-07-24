namespace CraftQuest.Domain.Entities;

public class Plan
{
    public int PlanId { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public decimal? MonthlyPrice { get; set; }
    public decimal? AnnualPrice { get; set; }
    public int? MaxQuizzes { get; set; }
    public int? MaxQuestionsPerQuiz { get; set; }
    /// <summary>Max questions per AI generation job for this plan.</summary>
    public int? MaxQuestionsPerAiGeneration { get; set; }
    public int MonthlyAiCredits { get; set; }
    public int MonthlyShareCodes { get; set; }
    /// <summary>Max quizzes a user may keep downloaded for offline practice (null = unlimited).</summary>
    public int? MaxOfflineQuizzes { get; set; }
    /// <summary>Max total storage in MB for offline quiz packages (null = unlimited).</summary>
    public int? MaxOfflineStorageMb { get; set; }
    public bool IsTeacherPlan { get; set; }
    public bool IsInstitutionPlan { get; set; }
    public bool IsActive { get; set; } = true;
}