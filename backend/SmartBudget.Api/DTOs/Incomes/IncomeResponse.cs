namespace SmartBudget.Api.DTOs.Incomes;

public sealed record IncomeResponse(
    Guid Id,
    decimal Amount,
    string? Description,
    DateOnly Date,
    DateTime CreatedAt);
