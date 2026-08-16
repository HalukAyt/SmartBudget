namespace SmartBudget.Api.DTOs.AI;

public sealed record CategorizeExpenseResponse(
    bool Success,
    Guid? CategoryId,
    string? Category,
    decimal? Confidence,
    bool RequiresManualSelection,
    string Message);
