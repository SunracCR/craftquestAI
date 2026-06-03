using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Services.Billing;

namespace CraftQuest.UnitTests.Billing;

public class AiCreditPeriodCalculatorTests
{
    [Fact]
    public void FreePlan_UsesCalendarMonthStart()
    {
        var now = new DateTime(2026, 7, 2, 12, 0, 0, DateTimeKind.Utc);
        var subscription = new UserSubscription
        {
            StartedAt = new DateTime(2026, 6, 30, 0, 0, 0, DateTimeKind.Utc),
            ProviderCode = "internal",
            BillingCycle = "monthly",
        };
        var plan = new Plan { Code = "free", MonthlyAiCredits = 20 };

        var periodStart = AiCreditPeriodCalculator.GetCreditPeriodStartUtc(
            subscription,
            plan,
            now);

        Assert.Equal(new DateTime(2026, 7, 1, 0, 0, 0, DateTimeKind.Utc), periodStart);
    }

    [Fact]
    public void PaidPlan_June30Purchase_July1StillSameBillingPeriod()
    {
        var startedAt = new DateTime(2026, 6, 30, 0, 0, 0, DateTimeKind.Utc);
        var now = new DateTime(2026, 7, 1, 12, 0, 0, DateTimeKind.Utc);
        var subscription = new UserSubscription
        {
            StartedAt = startedAt,
            ProviderCode = "paypal",
            BillingCycle = "monthly",
        };
        var plan = new Plan { Code = "pro", MonthlyAiCredits = 150 };

        var periodStart = AiCreditPeriodCalculator.GetCreditPeriodStartUtc(
            subscription,
            plan,
            now);

        Assert.Equal(startedAt, periodStart);
    }

    [Fact]
    public void PaidPlan_June30Purchase_July30StartsNewBillingPeriod()
    {
        var startedAt = new DateTime(2026, 6, 30, 0, 0, 0, DateTimeKind.Utc);
        var now = new DateTime(2026, 7, 30, 0, 0, 0, DateTimeKind.Utc);
        var subscription = new UserSubscription
        {
            StartedAt = startedAt,
            ProviderCode = "paypal",
            BillingCycle = "monthly",
        };
        var plan = new Plan { Code = "teacher", MonthlyAiCredits = 360 };

        var periodStart = AiCreditPeriodCalculator.GetCreditPeriodStartUtc(
            subscription,
            plan,
            now);

        Assert.Equal(new DateTime(2026, 7, 30, 0, 0, 0, DateTimeKind.Utc), periodStart);
    }
}
