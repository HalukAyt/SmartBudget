using SmartBudget.Api.DTOs.Categories;
using SmartBudget.Api.Enums;

namespace SmartBudget.Api.DTOs.Budgets;

public sealed record BudgetResponse(
    Guid Id,
    CategoryResponse Category,
    decimal LimitAmount,
    int Month,
    int Year,
    decimal SpentAmount,
    decimal UsagePercent,
    BudgetAlertStatus AlertStatus,
    DateTime CreatedAt);
