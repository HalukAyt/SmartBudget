using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using SmartBudget.Api.Data;
using SmartBudget.Api.HealthChecks;

namespace SmartBudget.Api.Tests.HealthChecks;

public sealed class DatabaseHealthCheckTests
{
    [Fact]
    public async Task Returns_healthy_when_database_can_be_reached()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        await using var dbContext = new AppDbContext(options);
        var healthCheck = new DatabaseHealthCheck(dbContext);

        var result = await healthCheck.CheckHealthAsync(new HealthCheckContext());

        Assert.Equal(HealthStatus.Healthy, result.Status);
    }

    [Fact]
    public async Task Returns_unhealthy_when_database_access_throws()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        var dbContext = new AppDbContext(options);
        await dbContext.DisposeAsync();
        var healthCheck = new DatabaseHealthCheck(dbContext);

        var result = await healthCheck.CheckHealthAsync(new HealthCheckContext());

        Assert.Equal(HealthStatus.Unhealthy, result.Status);
        Assert.NotNull(result.Exception);
    }
}
