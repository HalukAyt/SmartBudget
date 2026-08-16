namespace SmartBudget.Api.Services.AI;

public interface IAiCategorizationClient
{
    Task<string?> CategorizeAsync(
        string description,
        CancellationToken cancellationToken = default);
}
