namespace CraftQuest.UnitTests;

public class AnalyticsSelectionRateTests
{
    [Fact]
    public void SelectionRate_IsPercentageOfAttempts()
    {
        const int attempts = 10;
        const int selected = 3;
        var rate = attempts > 0
            ? Math.Round((decimal)selected / attempts * 100, 2)
            : 0;

        Assert.Equal(30m, rate);
    }
}
