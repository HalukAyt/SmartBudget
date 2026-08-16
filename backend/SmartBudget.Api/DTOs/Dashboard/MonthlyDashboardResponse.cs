namespace SmartBudget.Api.DTOs.Dashboard;

public sealed record MonthlyDashboardResponse(
    int Year,
    int Month,
    decimal TotalIncome,
    decimal TotalExpense,
    decimal Balance,
    IReadOnlyList<CategoryExpenseSummary> CategoryExpenses,
    IReadOnlyList<BudgetUsageSummary> BudgetUsages,
    decimal? PreviousMonthExpenseChangePercent,
    CategoryExpenseSummary? HighestSpendingCategory,
    CategoryIncreaseSummary? HighestIncreaseCategory,
    IReadOnlyList<MonthlyTrendPoint> LastSixMonthsTrend);
