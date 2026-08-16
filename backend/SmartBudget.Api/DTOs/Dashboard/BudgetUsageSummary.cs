using SmartBudget.Api.DTOs.Categories;
using SmartBudget.Api.Enums;

namespace SmartBudget.Api.DTOs.Dashboard;

public sealed record BudgetUsageSummary(
    Guid BudgetId,
    CategoryResponse Category,
    decimal LimitAmount,
    decimal SpentAmount,
    decimal UsagePercent,
    BudgetAlertStatus AlertStatus);
