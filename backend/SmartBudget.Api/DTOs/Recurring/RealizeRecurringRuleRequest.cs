using System.ComponentModel.DataAnnotations;

namespace SmartBudget.Api.DTOs.Recurring;

public sealed class RealizeRecurringRuleRequest
{
    [Range(1, 12)]
    public int Month { get; init; }

    [Range(RecurringValidation.MinYear, RecurringValidation.MaxYear)]
    public int Year { get; init; }

    [Range(
        typeof(decimal),
        "0.01",
        "79228162514264337593543950335",
        ParseLimitsInInvariantCulture = true)]
    public decimal? Amount { get; init; }

    [Range(
        typeof(decimal),
        "0.01",
        "79228162514264337593543950335",
        ParseLimitsInInvariantCulture = true)]
    public decimal? ConsumptionValue { get; init; }
}

internal static class RecurringValidation
{
    public const int MinYear = 2000;
    public const int MaxYear = 2100;
}
