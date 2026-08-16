namespace SmartBudget.Api.DTOs.Incomes;

public sealed record IncomeListItemResponse(
    Guid Id,
    decimal Amount,
    string? Description,
    DateOnly Date,
    DateTime CreatedAt);
