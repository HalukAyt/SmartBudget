namespace SmartBudget.Api.Common;

/// <summary>
/// Pure Europe/Istanbul midnight-scheduling math for the recurring rule
/// hosted service. Kept separate from the service itself so the delay
/// calculation can be unit tested without waiting on real timers.
/// </summary>
public static class RecurringScheduleHelper
{
    private const string IstanbulTimeZoneId = "Europe/Istanbul";

    /// <summary>
    /// The next Europe/Istanbul midnight (00:00) strictly after
    /// <paramref name="utcNow"/>, expressed as a UTC-anchored
    /// <see cref="DateTimeOffset"/>. If <paramref name="utcNow"/> lands
    /// exactly on a midnight instant, the following day's midnight is
    /// returned (never zero), matching a scheduler that has just fired and
    /// is computing its next target.
    /// </summary>
    public static DateTimeOffset GetNextIstanbulMidnightUtc(DateTimeOffset utcNow)
    {
        var istanbulTimeZone = TimeZoneInfo.FindSystemTimeZoneById(IstanbulTimeZoneId);
        var istanbulNow = TimeZoneInfo.ConvertTime(utcNow, istanbulTimeZone);
        var nextMidnightLocal = istanbulNow.Date.AddDays(1);
        var nextMidnightOffset = istanbulTimeZone.GetUtcOffset(nextMidnightLocal);

        return new DateTimeOffset(nextMidnightLocal, nextMidnightOffset);
    }

    /// <summary>
    /// How long to wait, from <paramref name="utcNow"/>, until the next
    /// Europe/Istanbul midnight. Never negative.
    /// </summary>
    public static TimeSpan GetDelayUntilNextIstanbulMidnight(DateTimeOffset utcNow)
    {
        var delay = GetNextIstanbulMidnightUtc(utcNow) - utcNow;
        return delay < TimeSpan.Zero ? TimeSpan.Zero : delay;
    }
}
