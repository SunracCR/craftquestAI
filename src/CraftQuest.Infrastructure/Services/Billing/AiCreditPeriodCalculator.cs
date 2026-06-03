using CraftQuest.Domain.Entities;

namespace CraftQuest.Infrastructure.Services.Billing;

/// Periodo de reinicio del cupo IA del plan.
/// Free usa mes calendario UTC; planes de pago recurrentes usan el ciclo de suscripción.
public static class AiCreditPeriodCalculator
{
    public static DateTime GetCreditPeriodStartUtc(
        UserSubscription subscription,
        Plan plan,
        DateTime nowUtc)
    {
        if (UsesSubscriptionBillingPeriod(plan, subscription))
        {
            return GetSubscriptionPeriodStartUtc(subscription, nowUtc);
        }

        return new DateTime(
            nowUtc.Year,
            nowUtc.Month,
            1,
            0,
            0,
            0,
            DateTimeKind.Utc);
    }

    internal static bool UsesSubscriptionBillingPeriod(Plan plan, UserSubscription subscription) =>
        !plan.Code.Equals("free", StringComparison.OrdinalIgnoreCase)
        && SubscriptionPeriodCalculator.IsRecurringProvider(subscription.ProviderCode);

    private static DateTime GetSubscriptionPeriodStartUtc(
        UserSubscription subscription,
        DateTime nowUtc)
    {
        var periodStart = ToUtc(subscription.StartedAt);
        var billingCycle = SubscriptionPeriodCalculator.NormalizeBillingCycle(subscription.BillingCycle);

        // Avanza periodos mensuales/anuales hasta encontrar el que contiene nowUtc.
        for (var i = 0; i < 240; i++)
        {
            var periodEnd = SubscriptionPeriodCalculator.CalculatePeriodEnd(periodStart, billingCycle);
            if (nowUtc < periodEnd)
            {
                return periodStart;
            }

            periodStart = periodEnd;
        }

        return periodStart;
    }

    private static DateTime ToUtc(DateTime value) =>
        value.Kind switch
        {
            DateTimeKind.Utc => value,
            DateTimeKind.Local => value.ToUniversalTime(),
            _ => DateTime.SpecifyKind(value, DateTimeKind.Utc),
        };
}
