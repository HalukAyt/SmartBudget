namespace SmartBudget.Api.Services.AI;

public interface IAiMonthlyAnalysisClient
{
    Task<string?> AnalyzeAsync(
        string dashboardSummaryJson,
        CancellationToken cancellationToken = default);
}
