using CraftQuest.Infrastructure.Services.Payments;

namespace CraftQuest.UnitTests.Payments;

public class GooglePlaySubscriptionActivationPolicyTests
{
    [Fact]
    public void IsActiveForVerification_ActiveState_ReturnsTrue()
    {
        var result = GooglePlaySubscriptionActivationPolicy.IsActiveForVerification(
            "SUBSCRIPTION_STATE_ACTIVE",
            periodEndUtc: null,
            utcNow: DateTime.UtcNow);

        Assert.True(result);
    }

    [Fact]
    public void IsActiveForVerification_PendingWithFutureExpiry_ReturnsTrue()
    {
        var now = new DateTime(2026, 9, 12, 12, 0, 0, DateTimeKind.Utc);

        var result = GooglePlaySubscriptionActivationPolicy.IsActiveForVerification(
            "SUBSCRIPTION_STATE_PENDING",
            periodEndUtc: now.AddDays(365),
            utcNow: now);

        Assert.True(result);
    }

    [Fact]
    public void IsActiveForVerification_PendingWithoutExpiry_ReturnsFalse()
    {
        var result = GooglePlaySubscriptionActivationPolicy.IsActiveForVerification(
            "SUBSCRIPTION_STATE_PENDING",
            periodEndUtc: null,
            utcNow: DateTime.UtcNow);

        Assert.False(result);
    }

    [Fact]
    public void IsActiveForVerification_ExpiredPending_ReturnsFalse()
    {
        var now = new DateTime(2026, 9, 12, 12, 0, 0, DateTimeKind.Utc);

        var result = GooglePlaySubscriptionActivationPolicy.IsActiveForVerification(
            "SUBSCRIPTION_STATE_PENDING",
            periodEndUtc: now.AddMinutes(-1),
            utcNow: now);

        Assert.False(result);
    }
}
