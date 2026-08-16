namespace SmartBudget.Api.DTOs.Dashboard;

public sealed record MonthlyTrendPoint(
    int Year,
    int Month,
    decimal TotalIncome,
    decimal TotalExpense,
    decimal Balance);
