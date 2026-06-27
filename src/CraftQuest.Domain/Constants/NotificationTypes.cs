namespace CraftQuest.Domain.Constants;

public static class NotificationTypes
{
    public const string QuizShared = "quiz_shared";
    public const string ClassJoined = "class_joined";
    public const string AssignmentCreated = "assignment_created";
    public const string AssignmentDueSoon = "assignment_due_soon";
    public const string AiJobCompleted = "ai_job_completed";
    public const string AiJobFailed = "ai_job_failed";
    public const string MembershipExpiring = "membership_expiring";
    public const string MembershipExpired = "membership_expired";
}

public static class NotificationOutboxEventTypes
{
    public const string AssignmentCreated = "assignment_created";
}
