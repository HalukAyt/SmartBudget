namespace SmartBudget.Api.DTOs.AI;

public sealed record MonthlyAnalysisResponse(
    bool Success,
    int Year,
    int Month,
    string? Analysis,
    bool RequiresManualReview,
    string Message);
