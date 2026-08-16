namespace SmartBudget.Api.DTOs.AI;

public sealed class MonthlyAnalysisRequest
{
    public int? Year { get; init; }
    public int? Month { get; init; }
}
