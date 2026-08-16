namespace SmartBudget.Api.DTOs.Dashboard;

public sealed record CategoryExpenseSummary(
    Guid CategoryId,
    string CategoryName,
    decimal Amount,
    decimal PercentageOfTotalExpense);
