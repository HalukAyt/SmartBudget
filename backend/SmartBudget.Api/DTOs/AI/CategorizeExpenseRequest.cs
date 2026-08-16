using System.ComponentModel.DataAnnotations;

namespace SmartBudget.Api.DTOs.AI;

public sealed class CategorizeExpenseRequest
{
    [Required]
    public string Description { get; init; } = string.Empty;
}
