using Microsoft.Extensions.Diagnostics.HealthChecks;
using SmartBudget.Api.Data;

namespace SmartBudget.Api.HealthChecks;

public sealed class DatabaseHealthCheck(AppDbContext dbContext) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var canConnect = await dbContext.Database.CanConnectAsync(cancellationToken);
            return canConnect
                ? HealthCheckResult.Healthy("Database connection is healthy.")
                : HealthCheckResult.Unhealthy("Database connection could not be established.");
        }
        catch (Exception exception)
        {
            return HealthCheckResult.Unhealthy("Database connection check failed.", exception);
        }
    }
}
