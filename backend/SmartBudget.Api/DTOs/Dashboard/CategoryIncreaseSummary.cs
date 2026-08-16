namespace SmartBudget.Api.DTOs.Dashboard;

public sealed record CategoryIncreaseSummary(
    Guid CategoryId,
    string CategoryName,
    decimal IncreaseAmount);
