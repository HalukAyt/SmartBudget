using SmartBudget.Api.DTOs.Categories;

namespace SmartBudget.Api.DTOs.Expenses;

public sealed record ExpenseListItemResponse(
    Guid Id,
    decimal Amount,
    string Description,
    CategoryResponse Category,
    DateOnly Date,
    DateTime CreatedAt,
    bool IsAiCategorized);
