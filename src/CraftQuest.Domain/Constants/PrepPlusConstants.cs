namespace CraftQuest.Domain.Constants;

public static class PrepPlusConstants
{
    public static class CategoryTypes
    {
        public const string Geographic = "geographic";
        public const string Thematic = "thematic";
    }

    public static readonly int[] AllowedDurationDays = [30, 60, 90, 183];

    /// <summary>Sentinel DurationDays for lifetime offers (use with IsLifetimeAccess=true).</summary>
    public const int LifetimeDurationDays = 0;

    public const int RequiredSampleQuestionCount = 3;
}
