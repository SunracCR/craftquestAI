namespace CraftQuest.Domain.Constants;

public static class PrepPlusConstants
{
    public static class CategoryTypes
    {
        public const string Geographic = "geographic";
        public const string Thematic = "thematic";
    }

    public static readonly int[] AllowedDurationDays = [30, 60, 90, 183];

    public const int RequiredSampleQuestionCount = 3;
}
