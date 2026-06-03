namespace CraftQuest.Application.Services;

/// <summary>
/// Practice session statuses that consume an assignment attempt slot.
/// </summary>
public static class AssignmentAttemptCounts
{
    public static readonly string[] CountedStatuses = ["finished", "forfeited"];

    public static bool CountsTowardMaxAttempts(string status) =>
        status is "finished" or "forfeited";
}
