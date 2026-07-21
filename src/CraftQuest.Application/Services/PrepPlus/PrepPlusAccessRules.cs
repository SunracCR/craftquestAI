namespace CraftQuest.Application.Services.PrepPlus;

public static class PrepPlusAccessRules
{
    public static string ResolveAccessState(QuizAccessSnapshot? access, DateTime now)
    {
        if (access is null)
        {
            return "none";
        }

        if (access.IsLifetimeAccess)
        {
            return "owned";
        }

        if (access.ExpiresAt is null)
        {
            return "none";
        }

        return access.ExpiresAt > now ? "active" : "expired";
    }

    public static bool CanPracticePurchaseAccess(QuizAccessSnapshot? access, DateTime now)
    {
        if (access is null || access.AccessType != "purchase")
        {
            return false;
        }

        return access.IsLifetimeAccess
            || (access.ExpiresAt is not null && access.ExpiresAt > now);
    }

    public static bool HasOwnedAccess(QuizAccessSnapshot? access) =>
        access is { AccessType: "purchase", IsLifetimeAccess: true };
}

public sealed record QuizAccessSnapshot(
    string AccessType,
    bool IsLifetimeAccess,
    DateTime? ExpiresAt);
