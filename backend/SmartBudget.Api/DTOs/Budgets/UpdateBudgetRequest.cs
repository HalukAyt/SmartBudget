using System.ComponentModel.DataAnnotations;

namespace SmartBudget.Api.DTOs.Budgets;

public sealed class UpdateBudgetRequest
{
    [Range(
        typeof(decimal),
        "0.01",
        "79228162514264337593543950335",
        ParseLimitsInInvariantCulture = true)]
    public decimal LimitAmount { get; init; }
}
