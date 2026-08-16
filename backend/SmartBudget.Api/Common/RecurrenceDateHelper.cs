namespace SmartBudget.Api.Common;

public static class RecurrenceDateHelper
{
    /// <summary>
    /// Resolves the recurrence occurrence date for a given year/month, using
    /// <paramref name="startDate"/>'s day-of-month as the anchor. If that day
    /// does not exist in the target month (e.g. 31 in February), the last day
    /// of the target month is used instead.
    /// </summary>
    public static DateOnly GetOccurrenceDate(DateOnly startDate, int year, int month)
    {
        var daysInMonth = DateTime.DaysInMonth(year, month);
        var day = Math.Min(startDate.Day, daysInMonth);
        return new DateOnly(year, month, day);
    }
}
