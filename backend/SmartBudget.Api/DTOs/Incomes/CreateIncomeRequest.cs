using System.ComponentModel.DataAnnotations;

namespace SmartBudget.Api.DTOs.Incomes;

public sealed class CreateIncomeRequest
{
    [Range(
        typeof(decimal),
        "0.01",
        "79228162514264337593543950335",
        ParseLimitsInInvariantCulture = true)]
    public decimal Amount { get; init; }

    public string? Description { get; init; }
    public DateOnly Date { get; init; }
}
