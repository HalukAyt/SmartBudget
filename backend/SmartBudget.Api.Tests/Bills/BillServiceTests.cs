using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using SmartBudget.Api.Common;
using SmartBudget.Api.Controllers;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.Bills;
using SmartBudget.Api.DTOs.Budgets;
using SmartBudget.Api.Entities;
using SmartBudget.Api.Enums;
using SmartBudget.Api.Services;

namespace SmartBudget.Api.Tests.Bills;

public sealed class BillServiceTests : IAsyncDisposable
{
    private static readonly DateTimeOffset FixedUtcNow =
        new(2026, 8, 16, 9, 0, 0, TimeSpan.Zero);

    private readonly AppDbContext _dbContext;
    private readonly BillService _billService;

    public BillServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _dbContext = new AppDbContext(options);
        _dbContext.Database.EnsureCreated();
        _billService = new BillService(
            _dbContext,
            new FixedTimeProvider(FixedUtcNow));
    }

    [Theory]
    [InlineData(BillType.Electricity, "kWh", "Elektrik faturası")]
    [InlineData(BillType.Water, "m³", "Su faturası")]
    [InlineData(BillType.NaturalGas, "m³", "Doğalgaz faturası")]
    public async Task Create_supported_bill_type_succeeds_with_derived_unit(
        BillType billType,
        string expectedUnit,
        string expectedDescription)
    {
        var user = await AddUserAsync();

        var response = await _billService.CreateAsync(
            user.Id,
            CreateRequest(billType));

        var storedBill = await _dbContext.Bills.SingleAsync();
        Assert.IsType<BillResponse>(response);
        Assert.Equal(billType, storedBill.BillType);
        Assert.Equal(billType, response.BillType);
        Assert.Equal(expectedUnit, response.ConsumptionUnit);
        Assert.Equal(DateTimeKind.Utc, response.CreatedAt.Kind);

        var storedExpense = await _dbContext.Expenses
            .Include(expense => expense.Category)
            .SingleAsync();
        Assert.Equal(storedBill.Id, storedExpense.BillId);
        Assert.Equal(user.Id, storedExpense.UserId);
        Assert.Equal(storedBill.Amount, storedExpense.Amount);
        Assert.Equal(storedBill.BillingDate, storedExpense.Date);
        Assert.Equal(SeedCategoryIds.Bill, storedExpense.CategoryId);
        Assert.Equal("Fatura", storedExpense.Category.Name);
        Assert.Equal(expectedDescription, storedExpense.Description);
        Assert.False(storedExpense.IsAiCategorized);
    }

    [Fact]
    public async Task Create_creates_exactly_one_linked_expense_per_bill()
    {
        var user = await AddUserAsync();

        var first = await _billService.CreateAsync(
            user.Id,
            CreateRequest(BillType.Electricity));
        var second = await _billService.CreateAsync(
            user.Id,
            CreateRequest(BillType.Water));

        Assert.Equal(2, await _dbContext.Bills.CountAsync());
        Assert.Equal(2, await _dbContext.Expenses.CountAsync());
        Assert.Single(await _dbContext.Expenses
            .Where(expense => expense.BillId == first.Id)
            .ToListAsync());
        Assert.Single(await _dbContext.Expenses
            .Where(expense => expense.BillId == second.Id)
            .ToListAsync());
    }

    [Fact]
    public async Task Create_failure_leaves_neither_bill_nor_expense()
    {
        var user = await AddUserAsync();
        var billCategory = await _dbContext.Categories
            .SingleAsync(category => category.Id == SeedCategoryIds.Bill);
        _dbContext.Categories.Remove(billCategory);
        await _dbContext.SaveChangesAsync();

        await Assert.ThrowsAsync<ValidationException>(() =>
            _billService.CreateAsync(user.Id, CreateRequest(BillType.Water)));

        Assert.Empty(_dbContext.Bills);
        Assert.Empty(_dbContext.Expenses);
    }

    [Fact]
    public void Bill_link_index_is_unique_and_optional()
    {
        var expenseType = _dbContext.Model.FindEntityType(typeof(Expense))!;
        var billIndex = Assert.Single(expenseType.GetIndexes().Where(index =>
            index.Properties.Select(property => property.Name)
                .SequenceEqual(new[] { nameof(Expense.BillId) })));

        Assert.True(billIndex.IsUnique);
        Assert.True(expenseType.FindProperty(nameof(Expense.BillId))!.IsNullable);
    }

    [Fact]
    public async Task Bill_expense_is_the_single_dashboard_expense_source()
    {
        var user = await AddUserAsync();
        await _billService.CreateAsync(
            user.Id,
            CreateRequest(BillType.Electricity, amount: 750));

        var dashboard = await new DashboardService(
            _dbContext,
            new FixedTimeProvider(FixedUtcNow))
            .GetMonthlyAsync(user.Id, 2026, 8);

        Assert.Equal(750, dashboard.TotalExpense);
        Assert.Single(await _dbContext.Expenses.ToListAsync());
    }

    [Fact]
    public async Task Bill_expense_increases_bill_category_budget_spending()
    {
        var user = await AddUserAsync();
        var budgetService = new BudgetService(_dbContext);
        await budgetService.CreateAsync(
            user.Id,
            new CreateBudgetRequest
            {
                CategoryId = SeedCategoryIds.Bill,
                LimitAmount = 1000,
                Month = 8,
                Year = 2026
            });
        await _billService.CreateAsync(
            user.Id,
            CreateRequest(BillType.NaturalGas, amount: 400));

        var budget = Assert.Single(await budgetService.GetAllAsync(user.Id));

        Assert.Equal(400, budget.SpentAmount);
        Assert.Equal(40, budget.UsagePercent);
        Assert.Equal(BudgetAlertStatus.Normal, budget.AlertStatus);
    }

    [Fact]
    public async Task Create_assigns_authenticated_user_id_and_request_has_no_user_id()
    {
        var authenticatedUser = await AddUserAsync();

        await _billService.CreateAsync(
            authenticatedUser.Id,
            CreateRequest(BillType.Electricity));

        Assert.Equal(
            authenticatedUser.Id,
            (await _dbContext.Bills.SingleAsync()).UserId);
        Assert.DoesNotContain(
            typeof(CreateBillRequest).GetProperties(),
            property => property.Name == "UserId");
    }

    [Fact]
    public void Consumption_unit_is_not_persisted_on_bill_entity()
    {
        Assert.DoesNotContain(
            typeof(Bill).GetProperties(),
            property => property.Name == "ConsumptionUnit");
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public async Task Create_rejects_non_positive_amount(decimal amount)
    {
        var user = await AddUserAsync();

        await Assert.ThrowsAsync<ValidationException>(() =>
            _billService.CreateAsync(
                user.Id,
                CreateRequest(BillType.Electricity, amount: amount)));

        Assert.Empty(_dbContext.Bills);
    }

    [Fact]
    public async Task Create_accepts_null_consumption_value()
    {
        var user = await AddUserAsync();

        var response = await _billService.CreateAsync(
            user.Id,
            CreateRequest(BillType.Water, consumptionValue: null));

        Assert.Null(response.ConsumptionValue);
        Assert.Null((await _dbContext.Bills.SingleAsync()).ConsumptionValue);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public async Task Create_rejects_non_positive_consumption_value(decimal value)
    {
        var user = await AddUserAsync();

        await Assert.ThrowsAsync<ValidationException>(() =>
            _billService.CreateAsync(
                user.Id,
                CreateRequest(BillType.Water, consumptionValue: value)));

        Assert.Empty(_dbContext.Bills);
    }

    [Fact]
    public async Task Create_rejects_invalid_bill_type()
    {
        var user = await AddUserAsync();

        await Assert.ThrowsAsync<ValidationException>(() =>
            _billService.CreateAsync(
                user.Id,
                CreateRequest((BillType)999)));

        Assert.Empty(_dbContext.Bills);
    }

    [Fact]
    public async Task Create_rejects_missing_billing_date()
    {
        var user = await AddUserAsync();
        var request = new CreateBillRequest
        {
            BillType = BillType.NaturalGas,
            Amount = 500,
            ConsumptionValue = 25,
            BillingDate = default
        };

        await Assert.ThrowsAsync<ValidationException>(() =>
            _billService.CreateAsync(user.Id, request));

        Assert.Empty(_dbContext.Bills);
    }

    [Fact]
    public async Task List_returns_only_authenticated_users_bills_as_dtos_without_tracking()
    {
        var authenticatedUser = await AddUserAsync();
        var otherUser = await AddUserAsync();
        await _billService.CreateAsync(
            authenticatedUser.Id,
            CreateRequest(BillType.Electricity));
        await _billService.CreateAsync(
            otherUser.Id,
            CreateRequest(BillType.Water));
        _dbContext.ChangeTracker.Clear();

        var bills = await _billService.GetAllAsync(authenticatedUser.Id);

        var bill = Assert.Single(bills);
        Assert.IsType<BillListItemResponse>(bill);
        Assert.Equal(BillType.Electricity, bill.BillType);
        Assert.Empty(_dbContext.ChangeTracker.Entries<Bill>());
    }

    [Fact]
    public async Task List_is_deterministically_ordered()
    {
        var user = await AddUserAsync();
        var lowestId = Guid.Parse("00000000-0000-0000-0000-000000000101");
        var highestId = Guid.Parse("00000000-0000-0000-0000-000000000102");
        var laterCreatedId = Guid.Parse("00000000-0000-0000-0000-000000000103");
        var newestDateId = Guid.Parse("00000000-0000-0000-0000-000000000104");
        var sameCreatedAt = new DateTime(2026, 8, 1, 10, 0, 0, DateTimeKind.Utc);

        _dbContext.Bills.AddRange(
            NewBill(lowestId, user.Id, BillType.Water, new DateOnly(2026, 7, 1), sameCreatedAt),
            NewBill(highestId, user.Id, BillType.Water, new DateOnly(2026, 7, 1), sameCreatedAt),
            NewBill(
                laterCreatedId,
                user.Id,
                BillType.Water,
                new DateOnly(2026, 7, 1),
                sameCreatedAt.AddHours(1)),
            NewBill(
                newestDateId,
                user.Id,
                BillType.Water,
                new DateOnly(2026, 8, 1),
                sameCreatedAt.AddHours(-1)));
        await _dbContext.SaveChangesAsync();
        _dbContext.ChangeTracker.Clear();

        var bills = await _billService.GetAllAsync(user.Id);

        Assert.Equal(
            new[] { newestDateId, laterCreatedId, highestId, lowestId },
            bills.Select(bill => bill.Id));
    }

    [Fact]
    public async Task Delete_allows_owner_and_removed_bill_no_longer_appears_in_list()
    {
        var owner = await AddUserAsync();
        var created = await _billService.CreateAsync(
            owner.Id,
            CreateRequest(BillType.Electricity));

        await _billService.DeleteAsync(owner.Id, created.Id);

        Assert.Empty(await _billService.GetAllAsync(owner.Id));
        Assert.False(await _dbContext.Bills.AnyAsync(bill => bill.Id == created.Id));
        Assert.False(await _dbContext.Expenses.AnyAsync(
            expense => expense.BillId == created.Id));
    }

    [Fact]
    public async Task Delete_for_other_users_bill_returns_not_found_and_preserves_bill()
    {
        var owner = await AddUserAsync();
        var otherUser = await AddUserAsync();
        var created = await _billService.CreateAsync(
            owner.Id,
            CreateRequest(BillType.Electricity));

        var exception = await Assert.ThrowsAsync<NotFoundException>(() =>
            _billService.DeleteAsync(otherUser.Id, created.Id));

        Assert.Equal("Bill was not found.", exception.Message);
        Assert.True(await _dbContext.Bills.AnyAsync(bill => bill.Id == created.Id));
        Assert.True(await _dbContext.Expenses.AnyAsync(
            expense => expense.BillId == created.Id));
    }

    [Fact]
    public async Task Delete_for_missing_bill_returns_not_found()
    {
        var user = await AddUserAsync();

        await Assert.ThrowsAsync<NotFoundException>(() =>
            _billService.DeleteAsync(user.Id, Guid.NewGuid()));
    }

    [Fact]
    public async Task Trend_uses_only_authenticated_users_data()
    {
        var authenticatedUser = await AddUserAsync();
        var otherUser = await AddUserAsync();
        await AddBillAsync(
            authenticatedUser.Id,
            BillType.Electricity,
            100,
            10,
            new DateOnly(2026, 8, 1));
        await AddBillAsync(
            otherUser.Id,
            BillType.Electricity,
            900,
            90,
            new DateOnly(2026, 8, 1));

        var trend = FindTrend(
            await _billService.GetTrendsAsync(authenticatedUser.Id),
            2026,
            8,
            BillType.Electricity);

        Assert.Equal(100, trend.TotalAmount);
        Assert.Equal(10, trend.TotalConsumption);
    }

    [Fact]
    public async Task Trend_contains_current_month_and_previous_five_months_for_each_bill_type()
    {
        var user = await AddUserAsync();

        var trends = await _billService.GetTrendsAsync(user.Id);

        Assert.Equal(18, trends.Count);
        Assert.Equal(
            new[]
            {
                (2026, 3),
                (2026, 4),
                (2026, 5),
                (2026, 6),
                (2026, 7),
                (2026, 8)
            },
            trends.Select(trend => (trend.Year, trend.Month)).Distinct());
        Assert.All(
            trends.GroupBy(trend => (trend.Year, trend.Month)),
            month => Assert.Equal(3, month.Count()));
    }

    [Fact]
    public async Task Trend_excludes_bills_older_than_six_month_window()
    {
        var user = await AddUserAsync();
        await AddBillAsync(
            user.Id,
            BillType.Water,
            500,
            50,
            new DateOnly(2026, 2, 28));
        await AddBillAsync(
            user.Id,
            BillType.Water,
            100,
            10,
            new DateOnly(2026, 3, 1));

        var march = FindTrend(
            await _billService.GetTrendsAsync(user.Id),
            2026,
            3,
            BillType.Water);

        Assert.Equal(100, march.TotalAmount);
        Assert.Equal(10, march.TotalConsumption);
    }

    [Fact]
    public async Task Trend_calculates_monthly_total_amount_including_null_consumption_bills()
    {
        var user = await AddUserAsync();
        await AddBillAsync(user.Id, BillType.Water, 100, null, new DateOnly(2026, 8, 1));
        await AddBillAsync(user.Id, BillType.Water, 250, 20, new DateOnly(2026, 8, 20));

        var trend = FindTrend(
            await _billService.GetTrendsAsync(user.Id),
            2026,
            8,
            BillType.Water);

        Assert.Equal(350, trend.TotalAmount);
    }

    [Theory]
    [InlineData(BillType.Electricity, "kWh")]
    [InlineData(BillType.Water, "m³")]
    [InlineData(BillType.NaturalGas, "m³")]
    public async Task Trend_calculates_consumption_separately_for_each_bill_type(
        BillType billType,
        string expectedUnit)
    {
        var user = await AddUserAsync();
        await AddBillAsync(user.Id, billType, 100, 10, new DateOnly(2026, 8, 1));
        await AddBillAsync(user.Id, billType, 150, 15, new DateOnly(2026, 8, 20));

        var trend = FindTrend(
            await _billService.GetTrendsAsync(user.Id),
            2026,
            8,
            billType);

        Assert.Equal(25, trend.TotalConsumption);
        Assert.Equal(expectedUnit, trend.ConsumptionUnit);
    }

    [Fact]
    public async Task Trend_does_not_mix_different_bill_types()
    {
        var user = await AddUserAsync();
        await AddBillAsync(user.Id, BillType.Electricity, 100, 10, new DateOnly(2026, 8, 1));
        await AddBillAsync(user.Id, BillType.Water, 200, 20, new DateOnly(2026, 8, 1));
        await AddBillAsync(user.Id, BillType.NaturalGas, 300, 30, new DateOnly(2026, 8, 1));

        var trends = await _billService.GetTrendsAsync(user.Id);

        Assert.Equal(10, FindTrend(trends, 2026, 8, BillType.Electricity).TotalConsumption);
        Assert.Equal(20, FindTrend(trends, 2026, 8, BillType.Water).TotalConsumption);
        Assert.Equal(30, FindTrend(trends, 2026, 8, BillType.NaturalGas).TotalConsumption);
    }

    [Fact]
    public async Task Null_consumption_is_not_added_as_a_fake_zero_record()
    {
        var user = await AddUserAsync();
        await AddBillAsync(user.Id, BillType.Electricity, 100, null, new DateOnly(2026, 8, 1));
        await AddBillAsync(user.Id, BillType.Electricity, 100, 10, new DateOnly(2026, 8, 2));
        await AddBillAsync(user.Id, BillType.Electricity, 100, 15, new DateOnly(2026, 8, 3));

        var trend = FindTrend(
            await _billService.GetTrendsAsync(user.Id),
            2026,
            8,
            BillType.Electricity);

        Assert.Equal(300, trend.TotalAmount);
        Assert.Equal(25, trend.TotalConsumption);
    }

    [Fact]
    public async Task Trend_total_consumption_is_null_when_month_type_has_no_consumption_value()
    {
        var user = await AddUserAsync();
        await AddBillAsync(user.Id, BillType.NaturalGas, 100, null, new DateOnly(2026, 8, 1));
        await AddBillAsync(user.Id, BillType.NaturalGas, 200, null, new DateOnly(2026, 8, 2));

        var trend = FindTrend(
            await _billService.GetTrendsAsync(user.Id),
            2026,
            8,
            BillType.NaturalGas);

        Assert.Equal(300, trend.TotalAmount);
        Assert.Null(trend.TotalConsumption);
    }

    [Fact]
    public async Task Empty_trend_point_has_zero_amount_and_null_consumption()
    {
        var user = await AddUserAsync();

        var trend = FindTrend(
            await _billService.GetTrendsAsync(user.Id),
            2026,
            8,
            BillType.Electricity);

        Assert.Equal(0, trend.TotalAmount);
        Assert.Null(trend.TotalConsumption);
    }

    [Fact]
    public async Task Trend_current_month_uses_europe_istanbul_calendar_date()
    {
        var service = new BillService(
            _dbContext,
            new FixedTimeProvider(
                new DateTimeOffset(2026, 8, 31, 21, 30, 0, TimeSpan.Zero)));
        var user = await AddUserAsync();

        var trends = await service.GetTrendsAsync(user.Id);

        Assert.Contains(trends, trend => trend.Year == 2026 && trend.Month == 9);
        Assert.DoesNotContain(trends, trend => trend.Year == 2026 && trend.Month == 3);
    }

    [Fact]
    public void Bills_controller_requires_authentication()
    {
        Assert.NotNull(Attribute.GetCustomAttribute(
            typeof(BillsController),
            typeof(AuthorizeAttribute)));
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
            PasswordHash = "not-used-in-bill-tests",
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync();
        return user;
    }

    private async Task AddBillAsync(
        Guid userId,
        BillType billType,
        decimal amount,
        decimal? consumptionValue,
        DateOnly billingDate)
    {
        _dbContext.Bills.Add(new Bill
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            BillType = billType,
            Amount = amount,
            ConsumptionValue = consumptionValue,
            BillingDate = billingDate,
            CreatedAt = DateTime.UtcNow
        });
        await _dbContext.SaveChangesAsync();
    }

    private static CreateBillRequest CreateRequest(
        BillType billType,
        decimal amount = 500,
        decimal? consumptionValue = 25,
        DateOnly? billingDate = null) =>
        new()
        {
            BillType = billType,
            Amount = amount,
            ConsumptionValue = consumptionValue,
            BillingDate = billingDate ?? new DateOnly(2026, 8, 16)
        };

    private static Bill NewBill(
        Guid id,
        Guid userId,
        BillType billType,
        DateOnly billingDate,
        DateTime createdAt) =>
        new()
        {
            Id = id,
            UserId = userId,
            BillType = billType,
            Amount = 100,
            ConsumptionValue = 10,
            BillingDate = billingDate,
            CreatedAt = createdAt
        };

    private static BillTrendResponse FindTrend(
        IReadOnlyList<BillTrendResponse> trends,
        int year,
        int month,
        BillType billType) =>
        Assert.Single(trends.Where(trend =>
            trend.Year == year &&
            trend.Month == month &&
            trend.BillType == billType));

    private sealed class FixedTimeProvider(DateTimeOffset utcNow) : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => utcNow;
    }
}
