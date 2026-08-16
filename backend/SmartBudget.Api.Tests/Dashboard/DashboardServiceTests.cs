using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using SmartBudget.Api.Controllers;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.Dashboard;
using SmartBudget.Api.Entities;
using SmartBudget.Api.Enums;
using SmartBudget.Api.Services;

namespace SmartBudget.Api.Tests.Dashboard;

public sealed class DashboardServiceTests : IAsyncDisposable
{
    private readonly AppDbContext _dbContext;
    private readonly DashboardService _dashboardService;

    public DashboardServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _dbContext = new AppDbContext(options);
        _dbContext.Database.EnsureCreated();
        _dashboardService = new DashboardService(
            _dbContext,
            new FixedTimeProvider(
                new DateTimeOffset(2026, 8, 16, 9, 0, 0, TimeSpan.Zero)));
    }

    [Fact]
    public async Task Default_report_month_uses_europe_istanbul_local_month()
    {
        var service = new DashboardService(
            _dbContext,
            new FixedTimeProvider(
                new DateTimeOffset(2026, 8, 31, 21, 30, 0, TimeSpan.Zero)));
        var user = await AddUserAsync();

        var response = await service.GetMonthlyAsync(user.Id, null, null);

        Assert.Equal(2026, response.Year);
        Assert.Equal(9, response.Month);
    }

    [Fact]
    public async Task Explicit_year_and_month_select_requested_period()
    {
        var user = await AddUserAsync();
        await AddIncomeAsync(user.Id, 500, new DateOnly(2025, 12, 1));

        var response = await _dashboardService.GetMonthlyAsync(user.Id, 2025, 12);

        Assert.Equal(2025, response.Year);
        Assert.Equal(12, response.Month);
        Assert.Equal(500, response.TotalIncome);
    }

    [Theory]
    [InlineData(2026, null)]
    [InlineData(null, 8)]
    public async Task Partial_year_month_pair_is_rejected(int? year, int? month)
    {
        var user = await AddUserAsync();

        await Assert.ThrowsAsync<ValidationException>(() =>
            _dashboardService.GetMonthlyAsync(user.Id, year, month));
    }

    [Theory]
    [InlineData(0)]
    [InlineData(13)]
    public async Task Invalid_month_is_rejected(int month)
    {
        var user = await AddUserAsync();

        await Assert.ThrowsAsync<ValidationException>(() =>
            _dashboardService.GetMonthlyAsync(user.Id, 2026, month));
    }

    [Theory]
    [InlineData(1999)]
    [InlineData(2101)]
    public async Task Unsupported_year_is_rejected(int year)
    {
        var user = await AddUserAsync();

        await Assert.ThrowsAsync<ValidationException>(() =>
            _dashboardService.GetMonthlyAsync(user.Id, year, 8));
    }

    [Fact]
    public async Task Total_income_uses_only_authenticated_user_and_selected_month()
    {
        var user = await AddUserAsync();
        var otherUser = await AddUserAsync();
        await AddIncomeAsync(user.Id, 500, new DateOnly(2026, 8, 1));
        await AddIncomeAsync(user.Id, 250, new DateOnly(2026, 8, 31));
        await AddIncomeAsync(user.Id, 900, new DateOnly(2026, 7, 31));
        await AddIncomeAsync(otherUser.Id, 1_000, new DateOnly(2026, 8, 1));

        var response = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);

        Assert.Equal(750, response.TotalIncome);
    }

    [Fact]
    public async Task Total_expense_uses_only_authenticated_user_and_selected_month()
    {
        var user = await AddUserAsync();
        var otherUser = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        await AddExpenseAsync(user.Id, category.Id, 400, new DateOnly(2026, 8, 1));
        await AddExpenseAsync(user.Id, category.Id, 100, new DateOnly(2026, 8, 31));
        await AddExpenseAsync(user.Id, category.Id, 900, new DateOnly(2026, 7, 31));
        await AddExpenseAsync(otherUser.Id, category.Id, 1_000, new DateOnly(2026, 8, 1));

        var response = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);

        Assert.Equal(500, response.TotalExpense);
    }

    [Fact]
    public async Task Empty_dashboard_returns_controlled_zero_and_null_values()
    {
        var user = await AddUserAsync();

        var response = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);

        Assert.Equal(0, response.TotalIncome);
        Assert.Equal(0, response.TotalExpense);
        Assert.Equal(0, response.Balance);
        Assert.Equal(0, response.PreviousMonthExpenseChangePercent);
        Assert.Empty(response.CategoryExpenses);
        Assert.Empty(response.BudgetUsages);
        Assert.Null(response.HighestSpendingCategory);
        Assert.Null(response.HighestIncreaseCategory);
    }

    [Fact]
    public async Task Balance_is_income_minus_expense_and_supports_negative_values()
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        await AddIncomeAsync(user.Id, 500, new DateOnly(2026, 8, 1));
        await AddExpenseAsync(user.Id, category.Id, 800, new DateOnly(2026, 8, 1));

        var response = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);

        Assert.Equal(-300, response.Balance);
    }

    [Fact]
    public async Task Category_expenses_are_grouped_percentaged_isolated_and_ordered()
    {
        var user = await AddUserAsync();
        var otherUser = await AddUserAsync();
        var market = await GetCategoryAsync("Market");
        var rent = await GetCategoryAsync("Kira");
        await AddExpenseAsync(user.Id, market.Id, 200, new DateOnly(2026, 8, 1));
        await AddExpenseAsync(user.Id, market.Id, 100, new DateOnly(2026, 8, 2));
        await AddExpenseAsync(user.Id, rent.Id, 100, new DateOnly(2026, 8, 1));
        await AddExpenseAsync(otherUser.Id, rent.Id, 900, new DateOnly(2026, 8, 1));

        var response = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);

        Assert.Equal(new[] { "Market", "Kira" }, response.CategoryExpenses.Select(x => x.CategoryName));
        Assert.Equal(300, response.CategoryExpenses[0].Amount);
        Assert.Equal(75, response.CategoryExpenses[0].PercentageOfTotalExpense);
        Assert.Equal(25, response.CategoryExpenses[1].PercentageOfTotalExpense);
    }

    [Fact]
    public async Task Category_order_tie_is_deterministic_by_name()
    {
        var user = await AddUserAsync();
        var market = await GetCategoryAsync("Market");
        var rent = await GetCategoryAsync("Kira");
        await AddExpenseAsync(user.Id, market.Id, 100, new DateOnly(2026, 8, 1));
        await AddExpenseAsync(user.Id, rent.Id, 100, new DateOnly(2026, 8, 1));

        var response = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);

        Assert.Equal(new[] { "Kira", "Market" }, response.CategoryExpenses.Select(x => x.CategoryName));
        Assert.Equal("Kira", response.HighestSpendingCategory!.CategoryName);
    }

    [Theory]
    [InlineData(790, 79, BudgetAlertStatus.Normal)]
    [InlineData(800, 80, BudgetAlertStatus.Warning)]
    [InlineData(1000, 100, BudgetAlertStatus.Exceeded)]
    [InlineData(1500, 150, BudgetAlertStatus.Exceeded)]
    public async Task Budget_usage_matches_existing_budget_rules(
        decimal spentAmount,
        decimal expectedPercent,
        BudgetAlertStatus expectedStatus)
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        await AddBudgetAsync(user.Id, category.Id, 1_000, 8, 2026);
        await AddExpenseAsync(user.Id, category.Id, spentAmount, new DateOnly(2026, 8, 1));

        var response = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);

        var usage = Assert.Single(response.BudgetUsages);
        Assert.Equal(spentAmount, usage.SpentAmount);
        Assert.Equal(expectedPercent, usage.UsagePercent);
        Assert.Equal(expectedStatus, usage.AlertStatus);
    }

    [Theory]
    [InlineData(150, 100, 50, false)]
    [InlineData(50, 100, -50, false)]
    [InlineData(0, 0, 0, false)]
    [InlineData(100, 0, 0, true)]
    public async Task Previous_month_expense_change_has_defined_zero_semantics(
        decimal current,
        decimal previous,
        decimal expected,
        bool expectNull)
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        if (current > 0)
        {
            await AddExpenseAsync(user.Id, category.Id, current, new DateOnly(2026, 8, 1));
        }

        if (previous > 0)
        {
            await AddExpenseAsync(user.Id, category.Id, previous, new DateOnly(2026, 7, 1));
        }

        var response = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);

        if (expectNull)
        {
            Assert.Null(response.PreviousMonthExpenseChangePercent);
        }
        else
        {
            Assert.Equal(expected, response.PreviousMonthExpenseChangePercent);
        }
    }

    [Fact]
    public async Task January_compares_against_previous_year_december()
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        await AddExpenseAsync(user.Id, category.Id, 150, new DateOnly(2026, 1, 1));
        await AddExpenseAsync(user.Id, category.Id, 100, new DateOnly(2025, 12, 1));

        var response = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 1);

        Assert.Equal(50, response.PreviousMonthExpenseChangePercent);
    }

    [Fact]
    public async Task Highest_spending_category_is_null_when_there_are_no_expenses()
    {
        var user = await AddUserAsync();

        var response = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);

        Assert.Null(response.HighestSpendingCategory);
    }

    [Fact]
    public async Task Highest_increase_uses_absolute_positive_difference_and_missing_month_as_zero()
    {
        var user = await AddUserAsync();
        var market = await GetCategoryAsync("Market");
        var rent = await GetCategoryAsync("Kira");
        await AddExpenseAsync(user.Id, market.Id, 300, new DateOnly(2026, 8, 1));
        await AddExpenseAsync(user.Id, market.Id, 100, new DateOnly(2026, 7, 1));
        await AddExpenseAsync(user.Id, rent.Id, 250, new DateOnly(2026, 8, 1));

        var response = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);

        Assert.Equal(rent.Id, response.HighestIncreaseCategory!.CategoryId);
        Assert.Equal(250, response.HighestIncreaseCategory.IncreaseAmount);
    }

    [Fact]
    public async Task Highest_increase_is_null_when_no_category_has_positive_increase()
    {
        var user = await AddUserAsync();
        var market = await GetCategoryAsync("Market");
        await AddExpenseAsync(user.Id, market.Id, 100, new DateOnly(2026, 8, 1));
        await AddExpenseAsync(user.Id, market.Id, 200, new DateOnly(2026, 7, 1));

        var response = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);

        Assert.Null(response.HighestIncreaseCategory);
    }

    [Fact]
    public async Task Highest_increase_tie_is_deterministic_and_other_user_is_excluded()
    {
        var user = await AddUserAsync();
        var otherUser = await AddUserAsync();
        var market = await GetCategoryAsync("Market");
        var rent = await GetCategoryAsync("Kira");
        await AddExpenseAsync(user.Id, market.Id, 100, new DateOnly(2026, 8, 1));
        await AddExpenseAsync(user.Id, rent.Id, 100, new DateOnly(2026, 8, 1));
        await AddExpenseAsync(otherUser.Id, market.Id, 9_000, new DateOnly(2026, 8, 1));

        var response = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);

        Assert.Equal("Kira", response.HighestIncreaseCategory!.CategoryName);
        Assert.Equal(100, response.HighestIncreaseCategory.IncreaseAmount);
    }

    [Fact]
    public async Task Last_six_months_trend_has_six_chronological_points_including_selected_month()
    {
        var user = await AddUserAsync();

        var response = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 8);

        Assert.Equal(6, response.LastSixMonthsTrend.Count);
        Assert.Equal(
            new[] { (2026, 3), (2026, 4), (2026, 5), (2026, 6), (2026, 7), (2026, 8) },
            response.LastSixMonthsTrend.Select(point => (point.Year, point.Month)));
        Assert.All(response.LastSixMonthsTrend, point =>
        {
            Assert.Equal(0, point.TotalIncome);
            Assert.Equal(0, point.TotalExpense);
            Assert.Equal(0, point.Balance);
        });
    }

    [Fact]
    public async Task Last_six_months_trend_handles_year_transition_and_user_isolation()
    {
        var user = await AddUserAsync();
        var otherUser = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        await AddIncomeAsync(user.Id, 500, new DateOnly(2025, 12, 1));
        await AddExpenseAsync(user.Id, category.Id, 200, new DateOnly(2026, 1, 1));
        await AddIncomeAsync(otherUser.Id, 9_000, new DateOnly(2025, 12, 1));

        var response = await _dashboardService.GetMonthlyAsync(user.Id, 2026, 2);

        Assert.Equal((2025, 9), (response.LastSixMonthsTrend[0].Year, response.LastSixMonthsTrend[0].Month));
        Assert.Equal((2026, 2), (response.LastSixMonthsTrend[5].Year, response.LastSixMonthsTrend[5].Month));
        var december = Assert.Single(response.LastSixMonthsTrend.Where(x => x.Year == 2025 && x.Month == 12));
        Assert.Equal(500, december.TotalIncome);
        var january = Assert.Single(response.LastSixMonthsTrend.Where(x => x.Year == 2026 && x.Month == 1));
        Assert.Equal(200, january.TotalExpense);
        Assert.Equal(-200, january.Balance);
    }

    [Fact]
    public void Dashboard_controller_requires_authentication_and_response_is_a_dto()
    {
        Assert.NotNull(Attribute.GetCustomAttribute(
            typeof(DashboardController),
            typeof(AuthorizeAttribute)));
        Assert.False(typeof(MonthlyDashboardResponse).IsAssignableTo(typeof(Expense)));
        Assert.False(typeof(MonthlyDashboardResponse).IsAssignableTo(typeof(Income)));
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
            PasswordHash = "not-used-in-dashboard-tests",
            CreatedAt = DateTime.UtcNow
        };
        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync();
        return user;
    }

    private Task<Category> GetCategoryAsync(string name) =>
        _dbContext.Categories.SingleAsync(category => category.Name == name);

    private async Task AddIncomeAsync(Guid userId, decimal amount, DateOnly date)
    {
        _dbContext.Incomes.Add(new Income
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Amount = amount,
            Date = date,
            CreatedAt = DateTime.UtcNow
        });
        await _dbContext.SaveChangesAsync();
    }

    private async Task AddExpenseAsync(
        Guid userId,
        Guid categoryId,
        decimal amount,
        DateOnly date)
    {
        _dbContext.Expenses.Add(new Expense
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            CategoryId = categoryId,
            Amount = amount,
            Description = "Dashboard test expense",
            Date = date,
            CreatedAt = DateTime.UtcNow
        });
        await _dbContext.SaveChangesAsync();
    }

    private async Task AddBudgetAsync(
        Guid userId,
        Guid categoryId,
        decimal limitAmount,
        int month,
        int year)
    {
        _dbContext.Budgets.Add(new Budget
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            CategoryId = categoryId,
            LimitAmount = limitAmount,
            Month = month,
            Year = year,
            CreatedAt = DateTime.UtcNow
        });
        await _dbContext.SaveChangesAsync();
    }

    private sealed class FixedTimeProvider(DateTimeOffset utcNow) : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => utcNow;
    }
}
