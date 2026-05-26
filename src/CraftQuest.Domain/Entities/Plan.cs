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
    public int MonthlyAiCredits { get; set; }
    public int MonthlyShareCodes { get; set; }
    public bool IsTeacherPlan { get; set; }
    public bool IsInstitutionPlan { get; set; }
    public bool IsActive { get; set; } = true;
}