using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;
using SmartBudget.Api.Common;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.Recurring;
using SmartBudget.Api.Entities;
using SmartBudget.Api.Enums;
using SmartBudget.Api.Services;

namespace SmartBudget.Api.Tests.Recurring;

/// <summary>
/// Covers the midnight-scheduling math directly (fast, no real waiting) and
/// exercises the hosted service's real loop only with tiny, millisecond-scale
/// delays — never the actual hours-long production interval.
/// </summary>
public sealed class RecurringRuleSchedulingTests
{
    [Fact]
    public void At_2330_istanbul_next_midnight_is_thirty_minutes_away()
    {
        // 2026-08-16 20:30 UTC = 2026-08-16 23:30 Europe/Istanbul (UTC+3).
        var utcNow = new DateTimeOffset(2026, 8, 16, 20, 30, 0, TimeSpan.Zero);

        var delay = RecurringScheduleHelper.GetDelayUntilNextIstanbulMidnight(utcNow);

        Assert.Equal(TimeSpan.FromMinutes(30), delay);
    }

    [Fact]
    public void At_0030_istanbul_next_midnight_is_the_following_day()
    {
        // 2026-08-15 21:30 UTC = 2026-08-16 00:30 Europe/Istanbul (UTC+3).
        var utcNow = new DateTimeOffset(2026, 8, 15, 21, 30, 0, TimeSpan.Zero);

        var delay = RecurringScheduleHelper.GetDelayUntilNextIstanbulMidnight(utcNow);

        Assert.Equal(TimeSpan.FromHours(23) + TimeSpan.FromMinutes(30), delay);
    }

    [Fact]
    public void Utc_to_istanbul_conversion_resolves_the_correct_next_midnight_instant()
    {
        var utcNow = new DateTimeOffset(2026, 8, 16, 20, 30, 0, TimeSpan.Zero);

        var nextMidnightUtc = RecurringScheduleHelper.GetNextIstanbulMidnightUtc(utcNow);

        // 2026-08-17 00:00 +03:00 Istanbul == 2026-08-16 21:00:00Z.
        Assert.Equal(
            new DateTimeOffset(2026, 8, 16, 21, 0, 0, TimeSpan.Zero),
            nextMidnightUtc);
        Assert.Equal(TimeSpan.FromHours(3), nextMidnightUtc.Offset);
    }

    [Fact]
    public void Exactly_at_midnight_the_next_target_is_the_following_day_not_zero()
    {
        // 2026-08-16 21:00:00Z == 2026-08-17 00:00:00 Europe/Istanbul exactly.
        var utcNow = new DateTimeOffset(2026, 8, 16, 21, 0, 0, TimeSpan.Zero);

        var nextMidnightUtc = RecurringScheduleHelper.GetNextIstanbulMidnightUtc(utcNow);

        Assert.Equal(new DateTimeOffset(2026, 8, 17, 21, 0, 0, TimeSpan.Zero), nextMidnightUtc);
    }

    [Fact]
    public async Task Startup_catchup_realizes_a_due_rule_immediately_without_waiting_for_midnight()
    {
        // "Now" is Istanbul noon: if the startup catch-up did not run
        // immediately (i.e. only the periodic midnight tick realized
        // rules), this test would have to wait ~12 real hours to observe
        // the Income — proving the immediate call is what makes it appear.
        var utcNow = new DateTimeOffset(2026, 8, 16, 9, 0, 0, TimeSpan.Zero);
        var timeProvider = new FixedTimeProvider(utcNow);

        await using var provider = BuildProvider(timeProvider);
        var user = await SeedUserAsync(provider);

        using (var setupScope = provider.CreateScope())
        {
            var recurringRuleService = setupScope.ServiceProvider
                .GetRequiredService<RecurringRuleService>();
            await recurringRuleService.CreateAsync(
                user.Id,
                new CreateRecurringRuleRequest
                {
                    RecordType = RecurringRecordType.Income,
                    StartDate = new DateOnly(2026, 8, 16),
                    DurationMonths = 6,
                    Amount = 45_000,
                    Description = "Maaş"
                });
        }

        using (var verifyScope = provider.CreateScope())
        {
            var dbContext = verifyScope.ServiceProvider.GetRequiredService<AppDbContext>();
            Assert.Equal(1, await dbContext.RecurringFinancialRules.CountAsync());
        }

        var capturingLogger = new CapturingLogger();
        var hostedService = new RecurringRuleRealizationHostedService(
            provider.GetRequiredService<IServiceScopeFactory>(),
            timeProvider,
            capturingLogger);

        await hostedService.StartAsync(CancellationToken.None);
        try
        {
            var realized = await WaitUntilAsync(async () =>
            {
                using var scope = provider.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                return await dbContext.Incomes.AnyAsync(income => income.UserId == user.Id);
            });

            Assert.True(
                realized,
                "Startup catch-up should realize the due rule immediately. Captured logs: "
                    + string.Join(" | ", capturingLogger.Messages));
        }
        finally
        {
            await hostedService.StopAsync(CancellationToken.None);
        }
    }

    [Fact]
    public async Task A_failing_run_does_not_fault_the_hosted_service_or_stop_scheduling()
    {
        // "Now" sits a few milliseconds before Istanbul midnight so the
        // loop's computed delay is tiny, letting several real iterations
        // happen within a fraction of a second instead of real hours.
        var utcNow = new DateTimeOffset(2026, 8, 16, 21, 0, 0, TimeSpan.Zero)
            - TimeSpan.FromMilliseconds(40);
        var timeProvider = new FixedTimeProvider(utcNow);

        // Deliberately omit BillService so resolving RecurringRuleService
        // inside the hosted service's scope always throws — simulating a
        // run that fails for a systemic (not per-rule) reason.
        var databaseName = Guid.NewGuid().ToString();
        var services = new ServiceCollection();
        services.AddDbContext<AppDbContext>(options =>
            options.UseInMemoryDatabase(databaseName));
        services.AddScoped<IncomeService>();
        services.AddScoped<ExpenseService>();
        services.AddScoped<RecurringRuleService>();
        services.AddSingleton<TimeProvider>(timeProvider);
        services.AddSingleton<ILogger<RecurringRuleService>>(
            NullLogger<RecurringRuleService>.Instance);
        await using var provider = services.BuildServiceProvider();

        var hostedService = new RecurringRuleRealizationHostedService(
            provider.GetRequiredService<IServiceScopeFactory>(),
            timeProvider,
            NullLogger<RecurringRuleRealizationHostedService>.Instance);

        await hostedService.StartAsync(CancellationToken.None);
        try
        {
            await Task.Delay(300);

            Assert.NotNull(hostedService.ExecuteTask);
            Assert.False(hostedService.ExecuteTask!.IsFaulted);
            Assert.False(hostedService.ExecuteTask.IsCompleted);
        }
        finally
        {
            await hostedService.StopAsync(CancellationToken.None);
        }

        Assert.False(hostedService.ExecuteTask!.IsFaulted);
    }

    private static ServiceProvider BuildProvider(TimeProvider timeProvider)
    {
        var databaseName = Guid.NewGuid().ToString();
        var services = new ServiceCollection();
        services.AddDbContext<AppDbContext>(options =>
            options.UseInMemoryDatabase(databaseName));
        services.AddScoped<IncomeService>();
        services.AddScoped<ExpenseService>();
        services.AddScoped<BillService>();
        services.AddScoped<RecurringRuleService>();
        services.AddSingleton(timeProvider);
        services.AddSingleton<ILogger<RecurringRuleService>>(
            NullLogger<RecurringRuleService>.Instance);
        return services.BuildServiceProvider();
    }

    private static async Task<User> SeedUserAsync(ServiceProvider provider)
    {
        using var scope = provider.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await dbContext.Database.EnsureCreatedAsync();

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = $"{Guid.NewGuid()}@example.com",
            PasswordHash = "not-used-in-scheduling-tests",
            CreatedAt = DateTime.UtcNow
        };
        dbContext.Users.Add(user);
        await dbContext.SaveChangesAsync();
        return user;
    }

    private static async Task<bool> WaitUntilAsync(
        Func<Task<bool>> condition,
        int maxIterations = 100,
        int intervalMilliseconds = 20)
    {
        for (var i = 0; i < maxIterations; i++)
        {
            if (await condition())
            {
                return true;
            }

            await Task.Delay(intervalMilliseconds);
        }

        return false;
    }

    private sealed class FixedTimeProvider(DateTimeOffset utcNow) : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => utcNow;
    }

    private sealed class CapturingLogger : ILogger<RecurringRuleRealizationHostedService>
    {
        public List<string> Messages { get; } = new();

        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;

        public bool IsEnabled(LogLevel logLevel) => true;

        public void Log<TState>(
            LogLevel logLevel,
            EventId eventId,
            TState state,
            Exception? exception,
            Func<TState, Exception?, string> formatter)
        {
            var message = formatter(state, exception);
            Messages.Add(exception is null ? message : $"{message} :: {exception}");
        }
    }
}
