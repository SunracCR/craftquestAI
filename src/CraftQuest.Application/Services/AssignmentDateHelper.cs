namespace CraftQuest.Application.Services;

/// <summary>
/// Assignment start/due values are calendar dates (whole days), not instants in a timezone.
/// </summary>
public static class AssignmentDateHelper
{
    public static DateTime? NormalizeToUtcDate(DateTime? value)
    {
        if (!value.HasValue)
        {
            return null;
        }

        var d = value.Value;
        return new DateTime(d.Year, d.Month, d.Day, 0, 0, 0, DateTimeKind.Utc);
    }

    public static DateOnly ToCalendarDate(DateTime value) =>
        new(value.Year, value.Month, value.Day);

    public static DateOnly TodayUtc() => DateOnly.FromDateTime(DateTime.UtcNow);

    public static DateOnly TodayForClient(int? utcOffsetMinutes)
    {
        if (utcOffsetMinutes is null)
        {
            return TodayUtc();
        }

        var local = DateTime.UtcNow.AddMinutes(utcOffsetMinutes.Value);
        return new DateOnly(local.Year, local.Month, local.Day);
    }

    public static bool IsNotYetOpen(DateTime? startsAt, DateTime utcNow)
    {
        if (!startsAt.HasValue)
        {
            return false;
        }

        return ToCalendarDate(utcNow) < ToCalendarDate(startsAt.Value);
    }

    public static bool IsNotYetOpen(DateTime? startsAt, int? utcOffsetMinutes) =>
        startsAt.HasValue
        && TodayForClient(utcOffsetMinutes) < ToCalendarDate(startsAt.Value);

    public static bool IsPastDue(DateTime? dueAt, DateTime utcNow)
    {
        if (!dueAt.HasValue)
        {
            return false;
        }

        return ToCalendarDate(utcNow) > ToCalendarDate(dueAt.Value);
    }

    public static bool IsPastDue(DateTime? dueAt, int? utcOffsetMinutes) =>
        dueAt.HasValue
        && TodayForClient(utcOffsetMinutes) > ToCalendarDate(dueAt.Value);

    public static bool IsValidDateRange(DateTime? startsAt, DateTime? dueAt)
    {
        if (!startsAt.HasValue || !dueAt.HasValue)
        {
            return true;
        }

        return ToCalendarDate(dueAt.Value) >= ToCalendarDate(startsAt.Value);
    }
}
