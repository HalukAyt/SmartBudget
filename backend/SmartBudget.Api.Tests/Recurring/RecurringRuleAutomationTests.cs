using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using SmartBudget.Api.Common;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.Budgets;
using SmartBudget.Api.DTOs.Recurring;
using SmartBudget.Api.Entities;
using SmartBudget.Api.Enums;
using SmartBudget.Api.Services;

namespace SmartBudget.Api.Tests.Recurring;

public sealed class RecurringRuleAutomationTests : IAsyncDisposable
{
    private readonly AppDbContext _dbContext;

    public RecurringRuleAutomationTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _dbContext = new AppDbContext(options);
        _dbContext.Database.EnsureCreated();
    }

    [Fact]
    public async Task Income_rule_realizes_automatically_on_due_day()
    {
        var user = await AddUserAsync();
        // Created a few days before the due day so create-time immediate
        // realization (tested separately in RecurringRuleServiceTests) does
        // not fire here; this test targets RunAutomaticRealizationAsync's
        // own scan/catch-up behavior on an already-existing rule.
        var createService = BuildService(Utc(2026, 8, 10, 9, 0));
        await createService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 16)));

        var dueService = BuildService(Utc(2026, 8, 16, 9, 0));
        var count = await dueService.RunAutomaticRealizationAsync();

        Assert.Equal(1, count);
        var income = await _dbContext.Incomes.SingleAsync();
        Assert.Equal(45_000, income.Amount);
        Assert.Equal(new DateOnly(2026, 8, 16), income.Date);
    }

    [Fact]
    public async Task Income_rule_does_not_realize_before_due_day()
    {
        var user = await AddUserAsync();
        var service = BuildService(Utc(2026, 8, 10, 9, 0));
        await service.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 16)));

        var count = await service.RunAutomaticRealizationAsync();

        Assert.Equal(0, count);
        Assert.Empty(_dbContext.Incomes);
    }

    [Fact]
    public async Task Second_run_on_the_same_day_does_not_duplicate()
    {
        var user = await AddUserAsync();
        var service = BuildService(Utc(2026, 8, 16, 9, 0));
        await service.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 16)));

        await service.RunAutomaticRealizationAsync();
        var secondCount = await service.RunAutomaticRealizationAsync();

        Assert.Equal(0, secondCount);
        Assert.Single(await _dbContext.Incomes.ToListAsync());
    }

    [Fact]
    public async Task Missed_due_day_is_caught_up_later_the_same_month()
    {
        var user = await AddUserAsync();
        var createService = BuildService(Utc(2026, 8, 1, 9, 0));
        await createService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 16)));

        // Backend was offline through the 16th and only comes back up on the 20th.
        var lateService = BuildService(Utc(2026, 8, 20, 7, 0));
        var count = await lateService.RunAutomaticRealizationAsync();

        Assert.Equal(1, count);
        var income = await _dbContext.Incomes.SingleAsync();
        Assert.Equal(new DateOnly(2026, 8, 16), income.Date);
    }

    [Fact]
    public async Task Expense_rule_realizes_automatically_on_due_day()
    {
        var user = await AddUserAsync();
        var rent = await GetCategoryAsync("Kira");
        var createService = BuildService(Utc(2026, 8, 1, 9, 0));
        await createService.CreateAsync(
            user.Id,
            ExpenseRequest(rent.Id, startDate: new DateOnly(2026, 8, 5)));

        var dueService = BuildService(Utc(2026, 8, 5, 9, 0));
        var count = await dueService.RunAutomaticRealizationAsync();

        Assert.Equal(1, count);
        var expense = await _dbContext.Expenses.SingleAsync();
        Assert.Equal(20_000, expense.Amount);
        Assert.Equal(rent.Id, expense.CategoryId);
    }

    [Fact]
    public async Task Auto_realized_expense_is_naturally_included_in_budget_spent_amount()
    {
        var user = await AddUserAsync();
        var rent = await GetCategoryAsync("Kira");
        var budgetService = new BudgetService(_dbContext);
        await budgetService.CreateAsync(
            user.Id,
            new CreateBudgetRequest
            {
                CategoryId = rent.Id,
                LimitAmount = 25_000,
                Month = 8,
                Year = 2026
            });
        var service = BuildService(Utc(2026, 8, 5, 9, 0));
        await service.CreateAsync(
            user.Id,
            ExpenseRequest(rent.Id, startDate: new DateOnly(2026, 8, 5)));

        await service.RunAutomaticRealizationAsync();

        var budget = Assert.Single(await budgetService.GetAllAsync(user.Id));
        Assert.Equal(20_000, budget.SpentAmount);
    }

    [Fact]
    public async Task Fixed_amount_bill_rule_auto_realizes_bill_and_linked_expense()
    {
        var user = await AddUserAsync();
        var createService = BuildService(Utc(2026, 8, 10, 9, 0));
        await createService.CreateAsync(
            user.Id,
            BillRuleRequest(startDate: new DateOnly(2026, 8, 16), amount: 750));

        var dueService = BuildService(Utc(2026, 8, 16, 9, 0));
        var count = await dueService.RunAutomaticRealizationAsync();

        Assert.Equal(1, count);
        var bill = await _dbContext.Bills.SingleAsync();
        Assert.Equal(750, bill.Amount);
        var expense = await _dbContext.Expenses.SingleAsync();
        Assert.Equal(bill.Id, expense.BillId);
        Assert.Equal(SeedCategoryIds.Bill, expense.CategoryId);
    }

    [Fact]
    public async Task Fixed_amount_bill_auto_realize_is_not_double_counted_on_dashboard()
    {
        var user = await AddUserAsync();
        var now = Utc(2026, 8, 16, 9, 0);
        var service = BuildService(now);
        await service.CreateAsync(
            user.Id,
            BillRuleRequest(startDate: new DateOnly(2026, 8, 16), amount: 750));

        await service.RunAutomaticRealizationAsync();

        var dashboard = await new DashboardService(_dbContext, new FixedTimeProvider(now))
            .GetMonthlyAsync(user.Id, 2026, 8);

        Assert.Equal(750, dashboard.TotalExpense);
        Assert.Single(await _dbContext.Expenses.ToListAsync());
    }

    [Fact]
    public async Task Unknown_amount_bill_rule_does_not_auto_realize()
    {
        var user = await AddUserAsync();
        var service = BuildService(Utc(2026, 8, 16, 9, 0));
        await service.CreateAsync(
            user.Id,
            BillRuleRequest(startDate: new DateOnly(2026, 8, 16), amount: null));

        var count = await service.RunAutomaticRealizationAsync();

        Assert.Equal(0, count);
        Assert.Empty(_dbContext.Bills);
        Assert.Empty(_dbContext.Expenses);
    }

    [Fact]
    public async Task Unknown_amount_bill_rule_stays_due_and_unrealized()
    {
        var user = await AddUserAsync();
        var service = BuildService(Utc(2026, 8, 16, 9, 0));
        await service.CreateAsync(
            user.Id,
            BillRuleRequest(startDate: new DateOnly(2026, 8, 16), amount: null));

        await service.RunAutomaticRealizationAsync();

        var rule = Assert.Single(await service.GetAllAsync(user.Id));
        Assert.False(rule.IsRealizedThisMonth);
    }

    [Fact]
    public async Task Inactive_rule_does_not_auto_realize()
    {
        var user = await AddUserAsync();
        var createService = BuildService(Utc(2026, 8, 10, 9, 0));
        var created = await createService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 16)));
        await createService.UpdateAsync(
            user.Id,
            created.Id,
            new UpdateRecurringRuleRequest
            {
                IsActive = false,
                EndDate = created.EndDate,
                Amount = created.Amount,
                Description = created.Description
            });

        var dueService = BuildService(Utc(2026, 8, 16, 9, 0));
        var count = await dueService.RunAutomaticRealizationAsync();

        Assert.Equal(0, count);
        Assert.Empty(_dbContext.Incomes);
    }

    [Fact]
    public async Task Rule_past_end_date_does_not_auto_realize()
    {
        var user = await AddUserAsync();
        var createService = BuildService(Utc(2026, 1, 10, 9, 0));
        await createService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 1, 16), durationMonths: 3));
        // EndDate = 2026-03-16; simulate the processor running months later.
        var laterService = BuildService(Utc(2026, 8, 16, 9, 0));

        var count = await laterService.RunAutomaticRealizationAsync();

        Assert.Equal(0, count);
        Assert.Empty(_dbContext.Incomes);
    }

    [Fact]
    public async Task Day_31_start_clamps_to_last_day_of_a_shorter_month()
    {
        var user = await AddUserAsync();
        var createService = BuildService(Utc(2026, 1, 25, 9, 0));
        await createService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 1, 31), durationMonths: 6));

        // 2026 is not a leap year: February's last day is the 28th.
        var febService = BuildService(Utc(2026, 2, 28, 9, 0));
        var count = await febService.RunAutomaticRealizationAsync();

        Assert.Equal(1, count);
        var income = await _dbContext.Incomes.SingleAsync();
        Assert.Equal(new DateOnly(2026, 2, 28), income.Date);
    }

    [Fact]
    public async Task Due_day_is_resolved_using_europe_istanbul_calendar_not_utc()
    {
        var user = await AddUserAsync();
        var createService = BuildService(Utc(2026, 8, 15, 9, 0));
        await createService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 16)));

        // 2026-08-15 21:30 UTC is already 2026-08-16 00:30 in Europe/Istanbul (UTC+3).
        var lateNightService = BuildService(new DateTimeOffset(2026, 8, 15, 21, 30, 0, TimeSpan.Zero));
        var count = await lateNightService.RunAutomaticRealizationAsync();

        Assert.Equal(1, count);
    }

    [Fact]
    public async Task Create_time_immediate_realization_respects_europe_istanbul_calendar_not_utc()
    {
        var user = await AddUserAsync();
        // 2026-08-15 21:30 UTC is already 2026-08-16 00:30 in Europe/Istanbul
        // (UTC+3): a rule due on the 16th must realize immediately at
        // create time, even though the UTC calendar date is still the 15th.
        var service = BuildService(new DateTimeOffset(2026, 8, 15, 21, 30, 0, TimeSpan.Zero));

        var response = await service.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 16)));

        Assert.True(response.IsRealizedThisMonth);
        Assert.Single(await _dbContext.Incomes.ToListAsync());
    }

    [Fact]
    public async Task One_rule_failing_does_not_block_other_rules_from_realizing()
    {
        var user = await AddUserAsync();
        var rent = await GetCategoryAsync("Kira");
        var createService = BuildService(Utc(2026, 8, 10, 9, 0));
        var brokenRule = await createService.CreateAsync(
            user.Id,
            ExpenseRequest(rent.Id, startDate: new DateOnly(2026, 8, 16)));
        await createService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 16)));

        var trackedRule = await _dbContext.RecurringFinancialRules
            .SingleAsync(candidate => candidate.Id == brokenRule.Id);
        trackedRule.CategoryId = Guid.NewGuid();
        await _dbContext.SaveChangesAsync();

        var service = BuildService(Utc(2026, 8, 16, 9, 0));
        var count = await service.RunAutomaticRealizationAsync();

        Assert.Equal(1, count);
        Assert.Empty(_dbContext.Expenses);
        Assert.Single(await _dbContext.Incomes.ToListAsync());
        Assert.False(await _dbContext.RecurringOccurrences.AnyAsync(
            occurrence => occurrence.RecurringRuleId == brokenRule.Id));
    }

    [Fact]
    public async Task Automatic_realization_keeps_records_scoped_to_their_own_owner()
    {
        var userA = await AddUserAsync();
        var userB = await AddUserAsync();
        var createService = BuildService(Utc(2026, 8, 10, 9, 0));
        await createService.CreateAsync(
            userA.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 16), amount: 1_000));
        await createService.CreateAsync(
            userB.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 16), amount: 2_000));

        var service = BuildService(Utc(2026, 8, 16, 9, 0));
        var count = await service.RunAutomaticRealizationAsync();

        Assert.Equal(2, count);
        var incomeA = await _dbContext.Incomes.SingleAsync(income => income.UserId == userA.Id);
        var incomeB = await _dbContext.Incomes.SingleAsync(income => income.UserId == userB.Id);
        Assert.Equal(1_000, incomeA.Amount);
        Assert.Equal(2_000, incomeB.Amount);
    }

    [Theory]
    [InlineData(2026, 1, 31, 2, 2026, 28)]
    [InlineData(2026, 1, 31, 4, 2026, 30)]
    [InlineData(2026, 1, 31, 5, 2026, 31)]
    [InlineData(2024, 1, 31, 2, 2024, 29)]
    public void RecurrenceDateHelper_clamps_to_last_day_of_shorter_months(
        int startYear,
        int startMonth,
        int startDay,
        int targetMonth,
        int targetYear,
        int expectedDay)
    {
        var startDate = new DateOnly(startYear, startMonth, startDay);

        var occurrence = RecurrenceDateHelper.GetOccurrenceDate(startDate, targetYear, targetMonth);

        Assert.Equal(new DateOnly(targetYear, targetMonth, expectedDay), occurrence);
    }

    public async ValueTask DisposeAsync()
    {
        await _dbContext.DisposeAsync();
    }

    private static DateTimeOffset Utc(int year, int month, int day, int hour, int minute) =>
        new(year, month, day, hour, minute, 0, TimeSpan.Zero);

    private RecurringRuleService BuildService(DateTimeOffset utcNow)
    {
        var timeProvider = new FixedTimeProvider(utcNow);
        var incomeService = new IncomeService(_dbContext);
        var expenseService = new ExpenseService(_dbContext);
        var billService = new BillService(_dbContext, timeProvider);

        return new RecurringRuleService(
            _dbContext,
            incomeService,
            expenseService,
            billService,
            timeProvider,
            NullLogger<RecurringRuleService>.Instance);
    }

    private async Task<User> AddUserAsync()
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = $"{Guid.NewGuid()}@example.com",
            PasswordHash = "not-used-in-automation-tests",
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync();
        return user;
    }

    private Task<Category> GetCategoryAsync(string name) =>
        _dbContext.Categories.SingleAsync(category => category.Name == name);

    private static CreateRecurringRuleRequest IncomeRequest(
        decimal amount = 45_000,
        DateOnly? startDate = null,
        int? durationMonths = 6) =>
        new()
        {
            RecordType = RecurringRecordType.Income,
            StartDate = startDate ?? new DateOnly(2026, 8, 16),
            DurationMonths = durationMonths,
            Amount = amount,
            Description = "Maaş"
        };

    private static CreateRecurringRuleRequest ExpenseRequest(
        Guid categoryId,
        decimal amount = 20_000,
        DateOnly? startDate = null,
        int? durationMonths = 12) =>
        new()
        {
            RecordType = RecurringRecordType.Expense,
            StartDate = startDate ?? new DateOnly(2026, 8, 16),
            DurationMonths = durationMonths,
            Amount = amount,
            CategoryId = categoryId,
            Description = "Kira"
        };

    private static CreateRecurringRuleRequest BillRuleRequest(
        DateOnly? startDate = null,
        int? durationMonths = 6,
        decimal? amount = null) =>
        new()
        {
            RecordType = RecurringRecordType.Bill,
            StartDate = startDate ?? new DateOnly(2026, 8, 16),
            DurationMonths = durationMonths,
            BillType = BillType.Electricity,
            Amount = amount
        };

    private sealed class FixedTimeProvider(DateTimeOffset utcNow) : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => utcNow;
    }
}
