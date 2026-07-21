using CraftQuest.Application.Services.PrepPlus;

namespace CraftQuest.UnitTests.PrepPlus;

public class PrepPlusAccessRulesTests
{
    private static readonly DateTime Now = new(2026, 7, 9, 12, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void ResolveAccessState_NullAccess_ReturnsNone()
    {
        Assert.Equal("none", PrepPlusAccessRules.ResolveAccessState(null, Now));
    }

    [Fact]
    public void ResolveAccessState_LifetimePurchase_ReturnsOwned()
    {
        var access = new QuizAccessSnapshot("purchase", IsLifetimeAccess: true, ExpiresAt: null);

        Assert.Equal("owned", PrepPlusAccessRules.ResolveAccessState(access, Now));
    }

    [Fact]
    public void ResolveAccessState_ActiveTemporal_ReturnsActive()
    {
        var access = new QuizAccessSnapshot(
            "purchase",
            IsLifetimeAccess: false,
            ExpiresAt: Now.AddDays(10));

        Assert.Equal("active", PrepPlusAccessRules.ResolveAccessState(access, Now));
    }

    [Fact]
    public void ResolveAccessState_ExpiredTemporal_ReturnsExpired()
    {
        var access = new QuizAccessSnapshot(
            "purchase",
            IsLifetimeAccess: false,
            ExpiresAt: Now.AddDays(-1));

        Assert.Equal("expired", PrepPlusAccessRules.ResolveAccessState(access, Now));
    }

    [Fact]
    public void ResolveAccessState_NullExpiresWithoutLifetime_ReturnsNone()
    {
        var access = new QuizAccessSnapshot("purchase", IsLifetimeAccess: false, ExpiresAt: null);

        Assert.Equal("none", PrepPlusAccessRules.ResolveAccessState(access, Now));
    }

    [Fact]
    public void CanPracticePurchaseAccess_Owned_ReturnsTrue()
    {
        var access = new QuizAccessSnapshot("purchase", IsLifetimeAccess: true, ExpiresAt: null);

        Assert.True(PrepPlusAccessRules.CanPracticePurchaseAccess(access, Now));
    }

    [Fact]
    public void CanPracticePurchaseAccess_ExpiredTemporal_ReturnsFalse()
    {
        var access = new QuizAccessSnapshot(
            "purchase",
            IsLifetimeAccess: false,
            ExpiresAt: Now.AddDays(-1));

        Assert.False(PrepPlusAccessRules.CanPracticePurchaseAccess(access, Now));
    }
}
