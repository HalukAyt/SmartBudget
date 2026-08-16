using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using SmartBudget.Api.Common;
using SmartBudget.Api.Controllers;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.Budgets;
using SmartBudget.Api.DTOs.Categories;
using SmartBudget.Api.Entities;
using SmartBudget.Api.Enums;
using SmartBudget.Api.Services;

namespace SmartBudget.Api.Tests.Budgets;

public sealed class BudgetServiceTests : IAsyncDisposable
{
    private readonly AppDbContext _dbContext;
    private readonly BudgetService _budgetService;

    public BudgetServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _dbContext = new AppDbContext(options);
        _dbContext.Database.EnsureCreated();
        _budgetService = new BudgetService(_dbContext);
    }

    [Fact]
    public async Task Create_with_valid_input_returns_dto_and_persists_budget()
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");

        var response = await _budgetService.CreateAsync(
            user.Id,
            CreateRequest(category.Id));

        var storedBudget = await _dbContext.Budgets.SingleAsync();
        Assert.IsType<BudgetResponse>(response);
        Assert.IsType<CategoryResponse>(response.Category);
        Assert.Equal(storedBudget.Id, response.Id);
        Assert.Equal(category.Id, response.Category.Id);
        Assert.Equal(1_000, response.LimitAmount);
        Assert.Equal(0, response.SpentAmount);
        Assert.Equal(0, response.UsagePercent);
        Assert.Equal(BudgetAlertStatus.Normal, response.AlertStatus);
        Assert.Equal(DateTimeKind.Utc, response.CreatedAt.Kind);
    }

    [Fact]
    public async Task Create_assigns_authenticated_user_id_and_request_dtos_have_no_user_id()
    {
        var authenticatedUser = await AddUserAsync();
        var category = await GetCategoryAsync("Ulaşım");

        await _budgetService.CreateAsync(
            authenticatedUser.Id,
            CreateRequest(category.Id));

        Assert.Equal(
            authenticatedUser.Id,
            (await _dbContext.Budgets.SingleAsync()).UserId);
        Assert.DoesNotContain(
            typeof(CreateBudgetRequest).GetProperties(),
            property => property.Name == "UserId");
        Assert.DoesNotContain(
            typeof(UpdateBudgetRequest).GetProperties(),
            property => property.Name == "UserId");
    }

    [Fact]
    public void Update_request_contains_only_limit_amount()
    {
        var property = Assert.Single(typeof(UpdateBudgetRequest).GetProperties());

        Assert.Equal("LimitAmount", property.Name);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public async Task Create_rejects_non_positive_limit_amount(decimal limitAmount)
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");

        await Assert.ThrowsAsync<ValidationException>(() =>
            _budgetService.CreateAsync(
                user.Id,
                CreateRequest(category.Id, limitAmount: limitAmount)));

        Assert.Empty(_dbContext.Budgets);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(13)]
    public async Task Create_rejects_month_outside_valid_range(int month)
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");

        await Assert.ThrowsAsync<ValidationException>(() =>
            _budgetService.CreateAsync(
                user.Id,
                CreateRequest(category.Id, month: month)));

        Assert.Empty(_dbContext.Budgets);
    }

    [Theory]
    [InlineData(1999)]
    [InlineData(2101)]
    public async Task Create_rejects_year_outside_supported_range(int year)
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");

        await Assert.ThrowsAsync<ValidationException>(() =>
            _budgetService.CreateAsync(
                user.Id,
                CreateRequest(category.Id, year: year)));

        Assert.Empty(_dbContext.Budgets);
    }

    [Fact]
    public async Task Create_rejects_invalid_category_id()
    {
        var user = await AddUserAsync();

        await Assert.ThrowsAsync<ValidationException>(() =>
            _budgetService.CreateAsync(user.Id, CreateRequest(Guid.NewGuid())));

        Assert.Empty(_dbContext.Budgets);
    }

    [Fact]
    public async Task Create_rejects_duplicate_for_same_user_category_month_and_year()
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        var request = CreateRequest(category.Id);
        await _budgetService.CreateAsync(user.Id, request);

        var exception = await Assert.ThrowsAsync<ConflictException>(() =>
            _budgetService.CreateAsync(user.Id, request));

        Assert.Equal(
            "A budget already exists for this category, month and year.",
            exception.Message);
        Assert.Single(_dbContext.Budgets);
    }

    [Fact]
    public async Task Different_user_can_create_same_category_month_and_year()
    {
        var firstUser = await AddUserAsync();
        var secondUser = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        var request = CreateRequest(category.Id);

        await _budgetService.CreateAsync(firstUser.Id, request);
        await _budgetService.CreateAsync(secondUser.Id, request);

        Assert.Equal(2, await _dbContext.Budgets.CountAsync());
    }

    [Fact]
    public async Task Same_user_can_create_budget_for_different_month()
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");

        await _budgetService.CreateAsync(user.Id, CreateRequest(category.Id, month: 7));
        await _budgetService.CreateAsync(user.Id, CreateRequest(category.Id, month: 8));

        Assert.Equal(2, await _dbContext.Budgets.CountAsync());
    }

    [Fact]
    public async Task Same_user_can_create_budget_for_different_category()
    {
        var user = await AddUserAsync();
        var market = await GetCategoryAsync("Market");
        var rent = await GetCategoryAsync("Kira");

        await _budgetService.CreateAsync(user.Id, CreateRequest(market.Id));
        await _budgetService.CreateAsync(user.Id, CreateRequest(rent.Id));

        Assert.Equal(2, await _dbContext.Budgets.CountAsync());
    }

    [Fact]
    public async Task List_returns_empty_for_user_without_budgets()
    {
        var user = await AddUserAsync();

        var budgets = await _budgetService.GetAllAsync(user.Id);

        Assert.Empty(budgets);
    }

    [Fact]
    public async Task List_returns_only_authenticated_users_budgets_as_dtos_without_tracking()
    {
        var authenticatedUser = await AddUserAsync();
        var otherUser = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        await _budgetService.CreateAsync(
            authenticatedUser.Id,
            CreateRequest(category.Id));
        await _budgetService.CreateAsync(
            otherUser.Id,
            CreateRequest(category.Id));
        _dbContext.ChangeTracker.Clear();

        var budgets = await _budgetService.GetAllAsync(authenticatedUser.Id);

        var budget = Assert.Single(budgets);
        Assert.IsType<BudgetListItemResponse>(budget);
        Assert.Equal(category.Id, budget.Category.Id);
        Assert.Empty(_dbContext.ChangeTracker.Entries<Budget>());
    }

    [Fact]
    public async Task List_is_deterministically_ordered()
    {
        var user = await AddUserAsync();
        var market = await GetCategoryAsync("Market");
        var transport = await GetCategoryAsync("Ulaşım");
        var olderYear = await _budgetService.CreateAsync(
            user.Id,
            CreateRequest(transport.Id, month: 12, year: 2025));
        var olderMonth = await _budgetService.CreateAsync(
            user.Id,
            CreateRequest(transport.Id, month: 7, year: 2026));
        var marketSameMonth = await _budgetService.CreateAsync(
            user.Id,
            CreateRequest(market.Id, month: 8, year: 2026));
        var transportSameMonth = await _budgetService.CreateAsync(
            user.Id,
            CreateRequest(transport.Id, month: 8, year: 2026));
        _dbContext.ChangeTracker.Clear();

        var budgets = await _budgetService.GetAllAsync(user.Id);

        Assert.Equal(
            new[]
            {
                marketSameMonth.Id,
                transportSameMonth.Id,
                olderMonth.Id,
                olderYear.Id
            },
            budgets.Select(budget => budget.Id));
    }

    [Fact]
    public async Task Spent_amount_includes_matching_user_category_month_and_year()
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        await _budgetService.CreateAsync(user.Id, CreateRequest(category.Id));
        await AddExpenseAsync(user.Id, category.Id, 250, new DateOnly(2026, 8, 1));
        await AddExpenseAsync(user.Id, category.Id, 150, new DateOnly(2026, 8, 31));

        var budget = Assert.Single(await _budgetService.GetAllAsync(user.Id));

        Assert.Equal(400, budget.SpentAmount);
    }

    [Fact]
    public async Task Spent_amount_excludes_other_users_expenses()
    {
        var user = await AddUserAsync();
        var otherUser = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        await _budgetService.CreateAsync(user.Id, CreateRequest(category.Id));
        await AddExpenseAsync(user.Id, category.Id, 100, new DateOnly(2026, 8, 1));
        await AddExpenseAsync(otherUser.Id, category.Id, 900, new DateOnly(2026, 8, 1));

        var budget = Assert.Single(await _budgetService.GetAllAsync(user.Id));

        Assert.Equal(100, budget.SpentAmount);
    }

    [Fact]
    public async Task Spent_amount_excludes_other_categories_expenses()
    {
        var user = await AddUserAsync();
        var market = await GetCategoryAsync("Market");
        var rent = await GetCategoryAsync("Kira");
        await _budgetService.CreateAsync(user.Id, CreateRequest(market.Id));
        await AddExpenseAsync(user.Id, market.Id, 100, new DateOnly(2026, 8, 1));
        await AddExpenseAsync(user.Id, rent.Id, 900, new DateOnly(2026, 8, 1));

        var budget = Assert.Single(await _budgetService.GetAllAsync(user.Id));

        Assert.Equal(100, budget.SpentAmount);
    }

    [Fact]
    public async Task Spent_amount_excludes_other_months_and_years_expenses()
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        await _budgetService.CreateAsync(user.Id, CreateRequest(category.Id));
        await AddExpenseAsync(user.Id, category.Id, 100, new DateOnly(2026, 8, 1));
        await AddExpenseAsync(user.Id, category.Id, 400, new DateOnly(2026, 7, 31));
        await AddExpenseAsync(user.Id, category.Id, 500, new DateOnly(2025, 8, 1));

        var budget = Assert.Single(await _budgetService.GetAllAsync(user.Id));

        Assert.Equal(100, budget.SpentAmount);
    }

    [Fact]
    public async Task Usage_percent_is_calculated_by_backend()
    {
        var budget = await GetBudgetWithSpentAmountAsync(limitAmount: 800, spentAmount: 200);

        Assert.Equal(25, budget.UsagePercent);
    }

    [Fact]
    public async Task Exactly_eighty_percent_is_warning()
    {
        var budget = await GetBudgetWithSpentAmountAsync(limitAmount: 1_000, spentAmount: 800);

        Assert.Equal(80, budget.UsagePercent);
        Assert.Equal(BudgetAlertStatus.Warning, budget.AlertStatus);
    }

    [Fact]
    public async Task Exactly_one_hundred_percent_is_exceeded()
    {
        var budget = await GetBudgetWithSpentAmountAsync(limitAmount: 1_000, spentAmount: 1_000);

        Assert.Equal(100, budget.UsagePercent);
        Assert.Equal(BudgetAlertStatus.Exceeded, budget.AlertStatus);
    }

    [Fact]
    public async Task Usage_above_one_hundred_percent_preserves_real_ratio()
    {
        var budget = await GetBudgetWithSpentAmountAsync(limitAmount: 1_000, spentAmount: 1_500);

        Assert.Equal(150, budget.UsagePercent);
        Assert.Equal(BudgetAlertStatus.Exceeded, budget.AlertStatus);
    }

    [Fact]
    public async Task Usage_below_eighty_percent_is_normal()
    {
        var budget = await GetBudgetWithSpentAmountAsync(limitAmount: 1_000, spentAmount: 799);

        Assert.Equal(79.9m, budget.UsagePercent);
        Assert.Equal(BudgetAlertStatus.Normal, budget.AlertStatus);
    }

    [Fact]
    public async Task Update_changes_only_limit_amount_and_returns_dto()
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        var created = await _budgetService.CreateAsync(
            user.Id,
            CreateRequest(category.Id, limitAmount: 1_000, month: 8, year: 2026));

        var updated = await _budgetService.UpdateAsync(
            user.Id,
            created.Id,
            new UpdateBudgetRequest { LimitAmount = 2_000 });

        Assert.IsType<BudgetResponse>(updated);
        Assert.Equal(2_000, updated.LimitAmount);
        Assert.Equal(created.Category, updated.Category);
        Assert.Equal(created.Month, updated.Month);
        Assert.Equal(created.Year, updated.Year);
        Assert.Equal(created.CreatedAt, updated.CreatedAt);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public async Task Update_rejects_non_positive_limit_amount(decimal limitAmount)
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        var created = await _budgetService.CreateAsync(
            user.Id,
            CreateRequest(category.Id));

        await Assert.ThrowsAsync<ValidationException>(() =>
            _budgetService.UpdateAsync(
                user.Id,
                created.Id,
                new UpdateBudgetRequest { LimitAmount = limitAmount }));
    }

    [Fact]
    public async Task Update_for_other_users_budget_returns_not_found()
    {
        var owner = await AddUserAsync();
        var otherUser = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        var created = await _budgetService.CreateAsync(
            owner.Id,
            CreateRequest(category.Id));

        var exception = await Assert.ThrowsAsync<NotFoundException>(() =>
            _budgetService.UpdateAsync(
                otherUser.Id,
                created.Id,
                new UpdateBudgetRequest { LimitAmount = 2_000 }));

        Assert.Equal("Budget was not found.", exception.Message);
    }

    [Fact]
    public async Task Delete_allows_owner_and_removed_budget_no_longer_appears_in_list()
    {
        var owner = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        var created = await _budgetService.CreateAsync(
            owner.Id,
            CreateRequest(category.Id));

        await _budgetService.DeleteAsync(owner.Id, created.Id);

        Assert.Empty(await _budgetService.GetAllAsync(owner.Id));
        Assert.False(await _dbContext.Budgets.AnyAsync(
            budget => budget.Id == created.Id));
    }

    [Fact]
    public async Task Delete_for_other_users_budget_returns_not_found_and_preserves_budget()
    {
        var owner = await AddUserAsync();
        var otherUser = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        var created = await _budgetService.CreateAsync(
            owner.Id,
            CreateRequest(category.Id));

        var exception = await Assert.ThrowsAsync<NotFoundException>(() =>
            _budgetService.DeleteAsync(otherUser.Id, created.Id));

        Assert.Equal("Budget was not found.", exception.Message);
        Assert.True(await _dbContext.Budgets.AnyAsync(
            budget => budget.Id == created.Id));
    }

    [Fact]
    public async Task Delete_for_missing_budget_returns_not_found()
    {
        var user = await AddUserAsync();

        await Assert.ThrowsAsync<NotFoundException>(() =>
            _budgetService.DeleteAsync(user.Id, Guid.NewGuid()));
    }

    [Fact]
    public void Budget_controller_requires_authentication()
    {
        Assert.NotNull(Attribute.GetCustomAttribute(
            typeof(BudgetsController),
            typeof(AuthorizeAttribute)));
    }

    public async ValueTask DisposeAsync()
    {
        await _dbContext.DisposeAsync();
    }

    private async Task<BudgetListItemResponse> GetBudgetWithSpentAmountAsync(
        decimal limitAmount,
        decimal spentAmount)
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        await _budgetService.CreateAsync(
            user.Id,
            CreateRequest(category.Id, limitAmount: limitAmount));
        await AddExpenseAsync(
            user.Id,
            category.Id,
            spentAmount,
            new DateOnly(2026, 8, 16));

        return Assert.Single(await _budgetService.GetAllAsync(user.Id));
    }

    private async Task<User> AddUserAsync()
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = $"{Guid.NewGuid()}@example.com",
            PasswordHash = "not-used-in-budget-tests",
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync();
        return user;
    }

    private Task<Category> GetCategoryAsync(string name) =>
        _dbContext.Categories.SingleAsync(category => category.Name == name);

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
            Description = "Budget calculation test",
            Date = date,
            CreatedAt = DateTime.UtcNow,
            IsAiCategorized = false
        });
        await _dbContext.SaveChangesAsync();
    }

    private static CreateBudgetRequest CreateRequest(
        Guid categoryId,
        decimal limitAmount = 1_000,
        int month = 8,
        int year = 2026) =>
        new()
        {
            CategoryId = categoryId,
            LimitAmount = limitAmount,
            Month = month,
            Year = year
        };
}
