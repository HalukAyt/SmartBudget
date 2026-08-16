using SmartBudget.Api.Common;

namespace SmartBudget.Api.Services;

/// <summary>
/// Realizes due recurring rules (Europe/Istanbul calendar) so Income/
/// Expense/fixed-amount Bill rules no longer require a manual "Bu Ay İçin
/// Oluştur" action. Runs once immediately at startup — covering catch-up if
/// the backend was offline past midnight on the recurrence day — and then
/// exactly at each subsequent Europe/Istanbul midnight, recomputed every
/// time rather than on a fixed interval. Intentionally a plain
/// <see cref="BackgroundService"/> — no Hangfire/Quartz/cron dependency —
/// since a single-instance MVP process needs nothing more than a resilient
/// timer loop.
/// </summary>
public sealed class RecurringRuleRealizationHostedService(
    IServiceScopeFactory scopeFactory,
    TimeProvider timeProvider,
    ILogger<RecurringRuleRealizationHostedService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Startup catch-up: always check immediately, independent of the
        // Europe/Istanbul clock, so a recurrence day missed while the
        // backend was offline (e.g. restarted at 10:30 instead of 00:00) is
        // realized right away instead of waiting for the next midnight.
        await RunOnceAsync(stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            var delay = RecurringScheduleHelper.GetDelayUntilNextIstanbulMidnight(
                timeProvider.GetUtcNow());

            try
            {
                await Task.Delay(delay, timeProvider, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }

            if (stoppingToken.IsCancellationRequested)
            {
                break;
            }

            await RunOnceAsync(stoppingToken);
        }
    }

    private async Task RunOnceAsync(CancellationToken stoppingToken)
    {
        try
        {
            using var scope = scopeFactory.CreateScope();
            var recurringRuleService = scope.ServiceProvider.GetRequiredService<RecurringRuleService>();
            var realizedCount = await recurringRuleService.RunAutomaticRealizationAsync(stoppingToken);

            if (realizedCount > 0)
            {
                logger.LogInformation(
                    "Automatic recurring realization created {Count} record(s).",
                    realizedCount);
            }
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Shutting down; nothing to log.
        }
        catch (Exception exception)
        {
            // A single failed run (or a resolution failure for one of the
            // scoped dependencies) must not stop the scheduler: log and let
            // the loop compute the next Europe/Istanbul midnight as usual.
            logger.LogError(exception, "Recurring rule realization run failed.");
        }
    }
}
