using System.ComponentModel.DataAnnotations;

namespace SmartBudget.Api.DTOs.Budgets;

public sealed class CreateBudgetRequest
{
    public Guid CategoryId { get; init; }

    [Range(
        typeof(decimal),
        "0.01",
        "79228162514264337593543950335",
        ParseLimitsInInvariantCulture = true)]
    public decimal LimitAmount { get; init; }

    [Range(1, 12)]
    public int Month { get; init; }

    [Range(BudgetValidation.MinYear, BudgetValidation.MaxYear)]
    public int Year { get; init; }
}

internal static class BudgetValidation
{
    public const int MinYear = 2000;
    public const int MaxYear = 2100;
}
