using System.ComponentModel.DataAnnotations;

namespace SmartBudget.Api.DTOs.Expenses;

public sealed class CreateExpenseRequest
{
    [Range(
        typeof(decimal),
        "0.01",
        "79228162514264337593543950335",
        ParseLimitsInInvariantCulture = true)]
    public decimal Amount { get; init; }

    [Required]
    public string Description { get; init; } = string.Empty;

    public Guid CategoryId { get; init; }
    public DateOnly Date { get; init; }
    public bool IsAiCategorized { get; init; }
}
