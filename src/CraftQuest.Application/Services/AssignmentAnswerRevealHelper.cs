using CraftQuest.Domain.Entities;

namespace CraftQuest.Application.Services;

public static class AssignmentAnswerRevealHelper
{
    public static bool CanStudentViewCorrectAnswers(
        Assignment assignment,
        int? clientUtcOffsetMinutes = null)
    {
        return assignment.ShowCorrectAnswersMode switch
        {
            "after_attempt" => true,
            "after_due_date" => AssignmentDateHelper.IsPastDue(
                assignment.DueAt,
                clientUtcOffsetMinutes),
            _ => false,
        };
    }
}
