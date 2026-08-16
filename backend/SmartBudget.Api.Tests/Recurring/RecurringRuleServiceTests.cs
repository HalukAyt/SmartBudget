using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using SmartBudget.Api.Common;
using SmartBudget.Api.Controllers;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.Budgets;
using SmartBudget.Api.DTOs.Recurring;
using SmartBudget.Api.Entities;
using SmartBudget.Api.Enums;
using SmartBudget.Api.Services;

namespace SmartBudget.Api.Tests.Recurring;

public sealed class RecurringRuleServiceTests : IAsyncDisposable
{
    private static readonly DateTimeOffset FixedUtcNow =
        new(2026, 8, 16, 9, 0, 0, TimeSpan.Zero);

    private readonly AppDbContext _dbContext;
    private readonly RecurringRuleService _recurringRuleService;
    private readonly BudgetService _budgetService;
    private readonly DashboardService _dashboardService;
    private readonly BillService _billService;

    public RecurringRuleServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _dbContext = new AppDbContext(options);
        _dbContext.Database.EnsureCreated();

        var timeProvider = new FixedTimeProvider(FixedUtcNow);
        var incomeService = new IncomeService(_dbContext);
        var expenseService = new ExpenseService(_dbContext);
        _billService = new BillService(_dbContext, timeProvider);
        _budgetService = new BudgetService(_dbContext);
        _dashboardService = new DashboardService(_dbContext, timeProvider);

        _recurringRuleService = new RecurringRuleService(
            _dbContext,
            incomeService,
            expenseService,
            _billService,
            timeProvider,
            NullLogger<RecurringRuleService>.Instance);
    }

    [Fact]
    public async Task Create_income_rule_succeeds()
    {
        var user = await AddUserAsync();

        // Not-yet-due StartDate: this test targets the general create
        // response shape, independent of create-time immediate realization
        // (covered separately below).
        var response = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 20)));

        Assert.Equal(RecurringRecordType.Income, response.RecordType);
        Assert.Equal(45_000, response.Amount);
        Assert.True(response.IsActive);
        Assert.False(response.IsRealizedThisMonth);
        Assert.Single(await _dbContext.RecurringFinancialRules.ToListAsync());
    }

    [Fact]
    public async Task Create_income_rule_realizes_immediately_when_due()
    {
        var user = await AddUserAsync();

        // FixedUtcNow is 2026-08-16 09:00 UTC (2026-08-16 in Europe/Istanbul);
        // StartDate = today, so the rule is due the moment it is created.
        var response = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 16)));

        Assert.True(response.IsRealizedThisMonth);
        var income = await _dbContext.Incomes.SingleAsync();
        Assert.Equal(45_000, income.Amount);
        Assert.Equal(user.Id, income.UserId);
        Assert.Equal(new DateOnly(2026, 8, 16), income.Date);

        var occurrence = await _dbContext.RecurringOccurrences.SingleAsync();
        Assert.Equal(response.Id, occurrence.RecurringRuleId);
        Assert.Equal(income.Id, occurrence.CreatedRecordId);

        var dashboard = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);
        Assert.Equal(45_000, dashboard.TotalIncome);
    }

    [Fact]
    public async Task Create_income_rule_with_future_start_date_does_not_realize_immediately()
    {
        var user = await AddUserAsync();

        var response = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 20)));

        Assert.False(response.IsRealizedThisMonth);
        Assert.Empty(_dbContext.Incomes);
        Assert.Empty(_dbContext.RecurringOccurrences);
    }

    [Fact]
    public async Task Create_income_rule_starting_tomorrow_does_not_realize_today()
    {
        // "Today" (per FixedUtcNow) is 2026-08-16 in Europe/Istanbul; StartDate
        // is the very next calendar day. A rule due tomorrow must not realize
        // today just because it falls within the current month — the day-level
        // comparison (today >= occurrenceDate) is what actually governs due-ness.
        var user = await AddUserAsync();

        var response = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 17)));

        Assert.False(response.IsRealizedThisMonth);
        Assert.Empty(_dbContext.Incomes);
        Assert.Empty(_dbContext.RecurringOccurrences);
        Assert.Equal(new DateOnly(2026, 8, 17), response.NextDueDate);

        var dashboard = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);
        Assert.Equal(0, dashboard.TotalIncome);
    }

    [Fact]
    public async Task Create_expense_rule_starting_tomorrow_does_not_realize_today()
    {
        var user = await AddUserAsync();
        var rent = await GetCategoryAsync("Kira");
        await _budgetService.CreateAsync(
            user.Id,
            new CreateBudgetRequest
            {
                CategoryId = rent.Id,
                LimitAmount = 25_000,
                Month = 8,
                Year = 2026
            });

        var response = await _recurringRuleService.CreateAsync(
            user.Id,
            ExpenseRequest(rent.Id, startDate: new DateOnly(2026, 8, 17)));

        Assert.False(response.IsRealizedThisMonth);
        Assert.Empty(_dbContext.Expenses);
        Assert.Empty(_dbContext.RecurringOccurrences);

        var budget = Assert.Single(await _budgetService.GetAllAsync(user.Id));
        Assert.Equal(0, budget.SpentAmount);
    }

    [Fact]
    public async Task Create_fixed_amount_bill_rule_starting_tomorrow_does_not_realize_today()
    {
        var user = await AddUserAsync();

        var response = await _recurringRuleService.CreateAsync(
            user.Id,
            BillRuleRequest(startDate: new DateOnly(2026, 8, 17), amount: 750));

        Assert.False(response.IsRealizedThisMonth);
        Assert.Empty(_dbContext.Bills);
        Assert.Empty(_dbContext.Expenses);
        Assert.Empty(_dbContext.RecurringOccurrences);

        var dashboard = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);
        Assert.Equal(0, dashboard.TotalExpense);
    }

    [Fact]
    public async Task Create_income_rule_starting_earlier_this_month_realizes_for_current_month_only()
    {
        var user = await AddUserAsync();

        // "Today" is 2026-08-16; StartDate is earlier this month (the 5th),
        // matching the automatic catch-up rule: current month is due, but
        // past months are never backfilled.
        var response = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 5)));

        Assert.True(response.IsRealizedThisMonth);
        var income = await _dbContext.Incomes.SingleAsync();
        Assert.Equal(new DateOnly(2026, 8, 5), income.Date);
        Assert.Single(await _dbContext.RecurringOccurrences.ToListAsync());
    }

    [Fact]
    public async Task Create_response_reflects_next_month_due_date_after_immediate_realization()
    {
        var user = await AddUserAsync();

        var response = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 16), durationMonths: 6));

        Assert.True(response.IsRealizedThisMonth);
        Assert.Equal(new DateOnly(2026, 9, 16), response.NextDueDate);
    }

    [Fact]
    public async Task Create_expense_rule_realizes_immediately_when_due()
    {
        var user = await AddUserAsync();
        var rent = await GetCategoryAsync("Kira");
        await _budgetService.CreateAsync(
            user.Id,
            new CreateBudgetRequest
            {
                CategoryId = rent.Id,
                LimitAmount = 25_000,
                Month = 8,
                Year = 2026
            });

        var response = await _recurringRuleService.CreateAsync(
            user.Id,
            ExpenseRequest(rent.Id, startDate: new DateOnly(2026, 8, 16)));

        Assert.True(response.IsRealizedThisMonth);
        var expense = await _dbContext.Expenses.SingleAsync();
        Assert.Equal(20_000, expense.Amount);
        Assert.Equal(rent.Id, expense.CategoryId);

        var budget = Assert.Single(await _budgetService.GetAllAsync(user.Id));
        Assert.Equal(20_000, budget.SpentAmount);
    }

    [Fact]
    public async Task Create_fixed_amount_bill_rule_realizes_immediately_when_due()
    {
        var user = await AddUserAsync();

        var response = await _recurringRuleService.CreateAsync(
            user.Id,
            BillRuleRequest(startDate: new DateOnly(2026, 8, 16), amount: 750));

        Assert.True(response.IsRealizedThisMonth);
        var bill = await _dbContext.Bills.SingleAsync();
        Assert.Equal(750, bill.Amount);

        var expense = await _dbContext.Expenses.SingleAsync();
        Assert.Equal(bill.Id, expense.BillId);
        Assert.Equal(SeedCategoryIds.Bill, expense.CategoryId);

        var dashboard = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);
        Assert.Equal(750, dashboard.TotalExpense);
        Assert.Single(await _dbContext.Expenses.ToListAsync());
    }

    [Fact]
    public async Task Create_unknown_amount_bill_rule_does_not_realize_immediately_and_stays_due()
    {
        var user = await AddUserAsync();

        var response = await _recurringRuleService.CreateAsync(
            user.Id,
            BillRuleRequest(startDate: new DateOnly(2026, 8, 16), amount: null));

        Assert.False(response.IsRealizedThisMonth);
        Assert.Empty(_dbContext.Bills);
        Assert.Empty(_dbContext.Expenses);
        Assert.Empty(_dbContext.RecurringOccurrences);

        // The user can still realize it manually once the real amount is known.
        var realized = await _recurringRuleService.RealizeAsync(
            user.Id,
            response.Id,
            RealizeRequest(amount: 300));
        Assert.NotEqual(Guid.Empty, realized.CreatedRecordId);
    }

    [Fact]
    public async Task Immediate_realization_and_a_later_background_run_do_not_duplicate()
    {
        var user = await AddUserAsync();
        var created = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 16)));
        Assert.True(created.IsRealizedThisMonth);

        var count = await _recurringRuleService.RunAutomaticRealizationAsync();

        Assert.Equal(0, count);
        Assert.Single(await _dbContext.Incomes.ToListAsync());
        Assert.Single(await _dbContext.RecurringOccurrences.ToListAsync());
    }

    [Fact]
    public async Task Manual_realize_after_immediate_create_time_realization_throws_conflict_not_an_unhandled_error()
    {
        var user = await AddUserAsync();
        var created = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 16)));
        Assert.True(created.IsRealizedThisMonth);

        // Simulates a racing/late manual realize request for the same month
        // the create-time path already realized: it must surface as a typed
        // ConflictException (mapped to 409 by the API), never an unhandled
        // exception or duplicate record.
        var exception = await Assert.ThrowsAsync<ConflictException>(() =>
            _recurringRuleService.RealizeAsync(user.Id, created.Id, RealizeRequest()));

        Assert.Equal(
            "A record has already been realized for this recurring rule and month.",
            exception.Message);
        Assert.Single(await _dbContext.Incomes.ToListAsync());
    }

    [Fact]
    public async Task Create_expense_rule_succeeds()
    {
        var user = await AddUserAsync();
        var rent = await GetCategoryAsync("Kira");

        var response = await _recurringRuleService.CreateAsync(
            user.Id,
            ExpenseRequest(rent.Id));

        Assert.Equal(RecurringRecordType.Expense, response.RecordType);
        Assert.Equal(rent.Id, response.Category!.Id);
        Assert.Equal(20_000, response.Amount);
    }

    [Fact]
    public async Task Create_bill_rule_succeeds()
    {
        var user = await AddUserAsync();

        var response = await _recurringRuleService.CreateAsync(
            user.Id,
            BillRuleRequest());

        Assert.Equal(RecurringRecordType.Bill, response.RecordType);
        Assert.Equal(BillType.Electricity, response.BillType);
        Assert.Null(response.Amount);
    }

    [Fact]
    public async Task Three_month_duration_computes_correct_end_date()
    {
        var user = await AddUserAsync();

        var response = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(durationMonths: 3));

        Assert.Equal(new DateOnly(2026, 10, 16), response.EndDate);
    }

    [Fact]
    public async Task Six_month_duration_computes_correct_end_date()
    {
        var user = await AddUserAsync();

        var response = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(durationMonths: 6));

        Assert.Equal(new DateOnly(2027, 1, 16), response.EndDate);
    }

    [Fact]
    public async Task Twelve_month_duration_computes_correct_end_date()
    {
        var user = await AddUserAsync();

        var response = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(durationMonths: 12));

        Assert.Equal(new DateOnly(2027, 7, 16), response.EndDate);
    }

    [Fact]
    public async Task Custom_end_date_before_start_date_is_rejected()
    {
        var user = await AddUserAsync();

        await Assert.ThrowsAsync<ValidationException>(() =>
            _recurringRuleService.CreateAsync(
                user.Id,
                IncomeRequest(
                    durationMonths: null,
                    endDate: new DateOnly(2026, 8, 1))));

        Assert.Empty(_dbContext.RecurringFinancialRules);
    }

    [Fact]
    public async Task Custom_end_date_equal_to_start_date_is_accepted()
    {
        var user = await AddUserAsync();

        var response = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(durationMonths: null, endDate: new DateOnly(2026, 8, 16)));

        Assert.Equal(new DateOnly(2026, 8, 16), response.EndDate);
    }

    [Fact]
    public async Task Update_for_other_users_rule_returns_not_found()
    {
        var owner = await AddUserAsync();
        var otherUser = await AddUserAsync();
        var created = await _recurringRuleService.CreateAsync(owner.Id, IncomeRequest());

        var exception = await Assert.ThrowsAsync<NotFoundException>(() =>
            _recurringRuleService.UpdateAsync(
                otherUser.Id,
                created.Id,
                UpdateRequest(created)));

        Assert.Equal("Recurring rule was not found.", exception.Message);
    }

    [Fact]
    public async Task Delete_for_other_users_rule_returns_not_found_and_preserves_rule()
    {
        var owner = await AddUserAsync();
        var otherUser = await AddUserAsync();
        var created = await _recurringRuleService.CreateAsync(owner.Id, IncomeRequest());

        var exception = await Assert.ThrowsAsync<NotFoundException>(() =>
            _recurringRuleService.DeleteAsync(otherUser.Id, created.Id));

        Assert.Equal("Recurring rule was not found.", exception.Message);
        Assert.True(await _dbContext.RecurringFinancialRules.AnyAsync(
            rule => rule.Id == created.Id));
    }

    [Fact]
    public async Task Due_query_returns_only_active_rules_within_date_range()
    {
        var user = await AddUserAsync();
        var currentRule = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 7, 1), durationMonths: 6));
        var futureRule = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 12, 1), durationMonths: 3));
        var inactiveRule = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 7, 1), durationMonths: 6));
        await _recurringRuleService.UpdateAsync(
            user.Id,
            inactiveRule.Id,
            UpdateRequest(inactiveRule, isActive: false));

        var due = await _recurringRuleService.GetDueAsync(user.Id);

        Assert.Single(due);
        Assert.Equal(currentRule.Id, due[0].Id);
        Assert.DoesNotContain(due, rule => rule.Id == futureRule.Id);
        Assert.DoesNotContain(due, rule => rule.Id == inactiveRule.Id);
    }

    [Fact]
    public async Task Realize_income_rule_creates_real_income()
    {
        var user = await AddUserAsync();
        var rule = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 20)));

        var result = await _recurringRuleService.RealizeAsync(
            user.Id,
            rule.Id,
            RealizeRequest());

        Assert.Equal(RecurringRecordType.Income, result.RecordType);
        var income = await _dbContext.Incomes.SingleAsync();
        Assert.Equal(result.CreatedRecordId, income.Id);
        Assert.Equal(45_000, income.Amount);
        Assert.Equal(user.Id, income.UserId);
    }

    [Fact]
    public async Task Realize_expense_rule_creates_real_expense()
    {
        var user = await AddUserAsync();
        var rent = await GetCategoryAsync("Kira");
        var rule = await _recurringRuleService.CreateAsync(
            user.Id,
            ExpenseRequest(rent.Id, startDate: new DateOnly(2026, 8, 20)));

        var result = await _recurringRuleService.RealizeAsync(
            user.Id,
            rule.Id,
            RealizeRequest());

        var expense = await _dbContext.Expenses.SingleAsync();
        Assert.Equal(result.CreatedRecordId, expense.Id);
        Assert.Equal(20_000, expense.Amount);
        Assert.Equal(rent.Id, expense.CategoryId);
        Assert.False(expense.IsAiCategorized);
    }

    [Fact]
    public async Task Realize_bill_rule_creates_real_bill_and_linked_expense()
    {
        var user = await AddUserAsync();
        var rule = await _recurringRuleService.CreateAsync(user.Id, BillRuleRequest());

        var result = await _recurringRuleService.RealizeAsync(
            user.Id,
            rule.Id,
            RealizeRequest(amount: 750, consumptionValue: 320));

        var bill = await _dbContext.Bills.SingleAsync();
        Assert.Equal(result.CreatedRecordId, bill.Id);
        Assert.Equal(750, bill.Amount);
        Assert.Equal(BillType.Electricity, bill.BillType);

        var expense = await _dbContext.Expenses.SingleAsync();
        Assert.Equal(bill.Id, expense.BillId);
        Assert.Equal(SeedCategoryIds.Bill, expense.CategoryId);
        Assert.Equal(750, expense.Amount);
    }

    [Fact]
    public async Task Second_realize_for_same_rule_and_month_throws_conflict()
    {
        var user = await AddUserAsync();
        var rule = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 20)));
        await _recurringRuleService.RealizeAsync(user.Id, rule.Id, RealizeRequest());

        var exception = await Assert.ThrowsAsync<ConflictException>(() =>
            _recurringRuleService.RealizeAsync(user.Id, rule.Id, RealizeRequest()));

        Assert.Equal(
            "A record has already been realized for this recurring rule and month.",
            exception.Message);
        Assert.Single(await _dbContext.Incomes.ToListAsync());
    }

    [Fact]
    public async Task Realize_by_other_user_returns_not_found()
    {
        var owner = await AddUserAsync();
        var otherUser = await AddUserAsync();
        var rule = await _recurringRuleService.CreateAsync(
            owner.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 20)));

        var exception = await Assert.ThrowsAsync<NotFoundException>(() =>
            _recurringRuleService.RealizeAsync(otherUser.Id, rule.Id, RealizeRequest()));

        Assert.Equal("Recurring rule was not found.", exception.Message);
        Assert.Empty(_dbContext.Incomes);
    }

    [Fact]
    public async Task Planned_rule_is_not_included_in_dashboard_totals()
    {
        var user = await AddUserAsync();
        await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 20)));

        var dashboard = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);

        Assert.Equal(0, dashboard.TotalIncome);
    }

    [Fact]
    public async Task Realized_income_is_included_in_dashboard_totals()
    {
        var user = await AddUserAsync();
        var rule = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 20)));
        await _recurringRuleService.RealizeAsync(user.Id, rule.Id, RealizeRequest());

        var dashboard = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);

        Assert.Equal(45_000, dashboard.TotalIncome);
    }

    [Fact]
    public async Task Planned_expense_rule_is_not_included_in_budget_spent_amount()
    {
        var user = await AddUserAsync();
        var rent = await GetCategoryAsync("Kira");
        await _budgetService.CreateAsync(
            user.Id,
            new CreateBudgetRequest
            {
                CategoryId = rent.Id,
                LimitAmount = 25_000,
                Month = 8,
                Year = 2026
            });
        await _recurringRuleService.CreateAsync(
            user.Id,
            ExpenseRequest(rent.Id, startDate: new DateOnly(2026, 8, 20)));

        var budget = Assert.Single(await _budgetService.GetAllAsync(user.Id));

        Assert.Equal(0, budget.SpentAmount);
    }

    [Fact]
    public async Task Realized_expense_rule_is_included_in_budget_spent_amount()
    {
        var user = await AddUserAsync();
        var rent = await GetCategoryAsync("Kira");
        await _budgetService.CreateAsync(
            user.Id,
            new CreateBudgetRequest
            {
                CategoryId = rent.Id,
                LimitAmount = 25_000,
                Month = 8,
                Year = 2026
            });
        var rule = await _recurringRuleService.CreateAsync(
            user.Id,
            ExpenseRequest(rent.Id, startDate: new DateOnly(2026, 8, 20)));

        await _recurringRuleService.RealizeAsync(user.Id, rule.Id, RealizeRequest());

        var budget = Assert.Single(await _budgetService.GetAllAsync(user.Id));

        Assert.Equal(20_000, budget.SpentAmount);
        Assert.Equal(80, budget.UsagePercent);
    }

    [Fact]
    public async Task Editing_rule_does_not_change_already_realized_record()
    {
        var user = await AddUserAsync();
        var rule = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 20)));
        await _recurringRuleService.RealizeAsync(user.Id, rule.Id, RealizeRequest());
        var realizedIncome = await _dbContext.Incomes.SingleAsync();

        await _recurringRuleService.UpdateAsync(
            user.Id,
            rule.Id,
            UpdateRequest(rule, amount: 99_000));

        var unchangedIncome = await _dbContext.Incomes.SingleAsync();
        Assert.Equal(realizedIncome.Amount, unchangedIncome.Amount);
        Assert.Equal(45_000, unchangedIncome.Amount);
    }

    [Fact]
    public async Task Deleting_rule_does_not_delete_already_realized_record()
    {
        var user = await AddUserAsync();
        var rule = await _recurringRuleService.CreateAsync(
            user.Id,
            IncomeRequest(startDate: new DateOnly(2026, 8, 20)));
        await _recurringRuleService.RealizeAsync(user.Id, rule.Id, RealizeRequest());

        await _recurringRuleService.DeleteAsync(user.Id, rule.Id);

        Assert.Single(await _dbContext.Incomes.ToListAsync());
        Assert.Empty(await _dbContext.RecurringFinancialRules.ToListAsync());
    }

    [Fact]
    public async Task Bill_trend_only_reflects_realized_bills_not_unrealized_rules()
    {
        var user = await AddUserAsync();
        await _recurringRuleService.CreateAsync(user.Id, BillRuleRequest());

        var trends = await _billService.GetTrendsAsync(user.Id);

        Assert.All(trends, trend => Assert.Equal(0, trend.TotalAmount));
    }

    [Fact]
    public async Task Bill_rule_allows_null_template_amount_but_requires_amount_at_realize()
    {
        var user = await AddUserAsync();
        var rule = await _recurringRuleService.CreateAsync(user.Id, BillRuleRequest());
        Assert.Null(rule.Amount);

        await Assert.ThrowsAsync<ValidationException>(() =>
            _recurringRuleService.RealizeAsync(
                user.Id,
                rule.Id,
                RealizeRequest(amount: null)));

        Assert.Empty(_dbContext.Bills);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-100)]
    public async Task Create_rejects_non_positive_amount_for_income(decimal amount)
    {
        var user = await AddUserAsync();

        await Assert.ThrowsAsync<ValidationException>(() =>
            _recurringRuleService.CreateAsync(user.Id, IncomeRequest(amount: amount)));

        Assert.Empty(_dbContext.RecurringFinancialRules);
    }

    [Fact]
    public async Task Create_expense_rule_without_category_is_rejected()
    {
        var user = await AddUserAsync();
        var request = new CreateRecurringRuleRequest
        {
            RecordType = RecurringRecordType.Expense,
            StartDate = new DateOnly(2026, 8, 16),
            DurationMonths = 6,
            Amount = 1_000
        };

        await Assert.ThrowsAsync<ValidationException>(() =>
            _recurringRuleService.CreateAsync(user.Id, request));
    }

    [Fact]
    public async Task Create_bill_rule_without_bill_type_is_rejected()
    {
        var user = await AddUserAsync();
        var request = new CreateRecurringRuleRequest
        {
            RecordType = RecurringRecordType.Bill,
            StartDate = new DateOnly(2026, 8, 16),
            DurationMonths = 6
        };

        await Assert.ThrowsAsync<ValidationException>(() =>
            _recurringRuleService.CreateAsync(user.Id, request));
    }

    [Fact]
    public async Task Create_rejects_category_id_on_income_rule()
    {
        var user = await AddUserAsync();
        var market = await GetCategoryAsync("Market");
        var request = new CreateRecurringRuleRequest
        {
            RecordType = RecurringRecordType.Income,
            StartDate = new DateOnly(2026, 8, 16),
            DurationMonths = 6,
            Amount = 1_000,
            CategoryId = market.Id
        };

        await Assert.ThrowsAsync<ValidationException>(() =>
            _recurringRuleService.CreateAsync(user.Id, request));
    }

    [Theory]
    [InlineData(1)]
    [InlineData(4)]
    [InlineData(24)]
    public async Task Create_rejects_unsupported_duration_months(int durationMonths)
    {
        var user = await AddUserAsync();

        await Assert.ThrowsAsync<ValidationException>(() =>
            _recurringRuleService.CreateAsync(
                user.Id,
                IncomeRequest(durationMonths: durationMonths)));
    }

    [Fact]
    public async Task Create_rejects_both_duration_and_custom_end_date()
    {
        var user = await AddUserAsync();
        var request = new CreateRecurringRuleRequest
        {
            RecordType = RecurringRecordType.Income,
            StartDate = new DateOnly(2026, 8, 16),
            DurationMonths = 6,
            EndDate = new DateOnly(2027, 1, 16),
            Amount = 1_000
        };

        await Assert.ThrowsAsync<ValidationException>(() =>
            _recurringRuleService.CreateAsync(user.Id, request));
    }

    [Fact]
    public void Occurrence_index_is_unique_on_rule_year_and_month()
    {
        var occurrenceType = _dbContext.Model.FindEntityType(typeof(RecurringOccurrence))!;
        var index = Assert.Single(occurrenceType.GetIndexes().Where(candidate =>
            candidate.Properties.Select(property => property.Name)
                .SequenceEqual(new[]
                {
                    nameof(RecurringOccurrence.RecurringRuleId),
                    nameof(RecurringOccurrence.Year),
                    nameof(RecurringOccurrence.Month)
                })));

        Assert.True(index.IsUnique);
    }

    [Fact]
    public void Recurring_rules_controller_requires_authentication()
    {
        Assert.NotNull(Attribute.GetCustomAttribute(
            typeof(RecurringRulesController),
            typeof(AuthorizeAttribute)));
    }

    [Fact]
    public void Requests_do_not_expose_a_user_id_property()
    {
        Assert.DoesNotContain(
            typeof(CreateRecurringRuleRequest).GetProperties(),
            property => property.Name == "UserId");
        Assert.DoesNotContain(
            typeof(UpdateRecurringRuleRequest).GetProperties(),
            property => property.Name == "UserId");
        Assert.DoesNotContain(
            typeof(RealizeRecurringRuleRequest).GetProperties(),
            property => property.Name == "UserId");
    }

    public async ValueTask DisposeAsync()
    {
        await _dbContext.DisposeAsync();
    }

    private async Task<User> AddUserAsync()
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = $"{Guid.NewGuid()}@example.com",
            PasswordHash = "not-used-in-recurring-tests",
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
        int? durationMonths = 6,
        DateOnly? endDate = null) =>
        new()
        {
            RecordType = RecurringRecordType.Income,
            StartDate = startDate ?? new DateOnly(2026, 8, 16),
            DurationMonths = durationMonths,
            EndDate = endDate,
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

    private static UpdateRecurringRuleRequest UpdateRequest(
        RecurringRuleResponse rule,
        bool isActive = true,
        decimal? amount = null) =>
        new()
        {
            IsActive = isActive,
            EndDate = rule.EndDate,
            Amount = amount ?? rule.Amount,
            Description = rule.Description,
            CategoryId = rule.Category?.Id,
            BillType = rule.BillType
        };

    private static RealizeRecurringRuleRequest RealizeRequest(
        int year = 2026,
        int month = 8,
        decimal? amount = null,
        decimal? consumptionValue = null) =>
        new()
        {
            Year = year,
            Month = month,
            Amount = amount,
            ConsumptionValue = consumptionValue
        };

    private sealed class FixedTimeProvider(DateTimeOffset utcNow) : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => utcNow;
    }
}
