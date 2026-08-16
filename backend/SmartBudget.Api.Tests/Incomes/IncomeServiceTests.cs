using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using SmartBudget.Api.Common;
using SmartBudget.Api.Controllers;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.Incomes;
using SmartBudget.Api.Entities;
using SmartBudget.Api.Services;

namespace SmartBudget.Api.Tests.Incomes;

public sealed class IncomeServiceTests : IAsyncDisposable
{
    private readonly AppDbContext _dbContext;
    private readonly IncomeService _incomeService;

    public IncomeServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _dbContext = new AppDbContext(options);
        _dbContext.Database.EnsureCreated();
        _incomeService = new IncomeService(_dbContext);
    }

    [Fact]
    public async Task Create_with_valid_input_returns_dto_and_persists_income()
    {
        var user = await AddUserAsync();

        var response = await _incomeService.CreateAsync(
            user.Id,
            CreateRequest(description: "Salary"));

        var storedIncome = await _dbContext.Incomes.SingleAsync();
        Assert.IsType<IncomeResponse>(response);
        Assert.Equal(storedIncome.Id, response.Id);
        Assert.Equal(1_000, response.Amount);
        Assert.Equal("Salary", response.Description);
        Assert.Equal(new DateOnly(2026, 8, 16), response.Date);
        Assert.Equal(DateTimeKind.Utc, response.CreatedAt.Kind);
    }

    [Fact]
    public async Task Create_assigns_authenticated_user_id_and_request_has_no_user_id()
    {
        var authenticatedUser = await AddUserAsync();

        await _incomeService.CreateAsync(authenticatedUser.Id, CreateRequest());

        var storedIncome = await _dbContext.Incomes.SingleAsync();
        Assert.Equal(authenticatedUser.Id, storedIncome.UserId);
        Assert.DoesNotContain(
            typeof(CreateIncomeRequest).GetProperties(),
            property => property.Name == "UserId");
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public async Task Create_rejects_non_positive_amount(decimal amount)
    {
        var user = await AddUserAsync();

        await Assert.ThrowsAsync<ValidationException>(() =>
            _incomeService.CreateAsync(user.Id, CreateRequest(amount: amount)));

        Assert.Empty(_dbContext.Incomes);
    }

    [Fact]
    public async Task Create_accepts_null_description()
    {
        var user = await AddUserAsync();

        var response = await _incomeService.CreateAsync(
            user.Id,
            CreateRequest(description: null));

        Assert.Null(response.Description);
        Assert.Null((await _dbContext.Incomes.SingleAsync()).Description);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    public async Task Create_normalizes_empty_or_whitespace_description_to_null(
        string description)
    {
        var user = await AddUserAsync();

        var response = await _incomeService.CreateAsync(
            user.Id,
            CreateRequest(description: description));

        Assert.Null(response.Description);
        Assert.Null((await _dbContext.Incomes.SingleAsync()).Description);
    }

    [Fact]
    public async Task Create_trims_description()
    {
        var user = await AddUserAsync();

        var response = await _incomeService.CreateAsync(
            user.Id,
            CreateRequest(description: "  Monthly salary  "));

        Assert.Equal("Monthly salary", response.Description);
        Assert.Equal(
            "Monthly salary",
            (await _dbContext.Incomes.SingleAsync()).Description);
    }

    [Fact]
    public async Task Create_rejects_missing_date()
    {
        var user = await AddUserAsync();
        var request = new CreateIncomeRequest
        {
            Amount = 1_000,
            Description = "Test income",
            Date = default
        };

        await Assert.ThrowsAsync<ValidationException>(() =>
            _incomeService.CreateAsync(user.Id, request));

        Assert.Empty(_dbContext.Incomes);
    }

    [Fact]
    public async Task List_returns_only_authenticated_users_incomes_as_dtos()
    {
        var authenticatedUser = await AddUserAsync();
        var otherUser = await AddUserAsync();
        await _incomeService.CreateAsync(
            authenticatedUser.Id,
            CreateRequest(description: "Mine"));
        await _incomeService.CreateAsync(
            otherUser.Id,
            CreateRequest(description: "Not mine"));
        _dbContext.ChangeTracker.Clear();

        var incomes = await _incomeService.GetAllAsync(authenticatedUser.Id);

        var income = Assert.Single(incomes);
        Assert.IsType<IncomeListItemResponse>(income);
        Assert.Equal("Mine", income.Description);
        Assert.Empty(_dbContext.ChangeTracker.Entries<Income>());
    }

    [Fact]
    public async Task List_is_deterministically_ordered_by_date_created_at_and_id_descending()
    {
        var user = await AddUserAsync();
        var lowestId = Guid.Parse("00000000-0000-0000-0000-000000000101");
        var highestId = Guid.Parse("00000000-0000-0000-0000-000000000102");
        var laterCreatedId = Guid.Parse("00000000-0000-0000-0000-000000000103");
        var newestDateId = Guid.Parse("00000000-0000-0000-0000-000000000104");
        var sameCreatedAt = new DateTime(2026, 1, 1, 10, 0, 0, DateTimeKind.Utc);

        _dbContext.Incomes.AddRange(
            NewIncome(lowestId, user.Id, new DateOnly(2026, 1, 1), sameCreatedAt),
            NewIncome(highestId, user.Id, new DateOnly(2026, 1, 1), sameCreatedAt),
            NewIncome(
                laterCreatedId,
                user.Id,
                new DateOnly(2026, 1, 1),
                sameCreatedAt.AddHours(1)),
            NewIncome(
                newestDateId,
                user.Id,
                new DateOnly(2026, 2, 1),
                sameCreatedAt.AddHours(-1)));
        await _dbContext.SaveChangesAsync();
        _dbContext.ChangeTracker.Clear();

        var incomes = await _incomeService.GetAllAsync(user.Id);

        Assert.Equal(
            new[] { newestDateId, laterCreatedId, highestId, lowestId },
            incomes.Select(income => income.Id));
    }

    [Fact]
    public async Task Delete_allows_owner_and_removed_income_no_longer_appears_in_list()
    {
        var owner = await AddUserAsync();
        var created = await _incomeService.CreateAsync(owner.Id, CreateRequest());

        await _incomeService.DeleteAsync(owner.Id, created.Id);

        Assert.Empty(await _incomeService.GetAllAsync(owner.Id));
        Assert.False(await _dbContext.Incomes.AnyAsync(
            income => income.Id == created.Id));
    }

    [Fact]
    public async Task Delete_for_other_users_income_returns_not_found_and_preserves_income()
    {
        var owner = await AddUserAsync();
        var otherUser = await AddUserAsync();
        var created = await _incomeService.CreateAsync(owner.Id, CreateRequest());

        var exception = await Assert.ThrowsAsync<NotFoundException>(() =>
            _incomeService.DeleteAsync(otherUser.Id, created.Id));

        Assert.Equal("Income was not found.", exception.Message);
        Assert.True(await _dbContext.Incomes.AnyAsync(
            income => income.Id == created.Id));
    }

    [Fact]
    public async Task Delete_for_missing_income_returns_not_found()
    {
        var user = await AddUserAsync();

        var exception = await Assert.ThrowsAsync<NotFoundException>(() =>
            _incomeService.DeleteAsync(user.Id, Guid.NewGuid()));

        Assert.Equal("Income was not found.", exception.Message);
    }

    [Fact]
    public void Income_controller_requires_authentication()
    {
        Assert.NotNull(Attribute.GetCustomAttribute(
            typeof(IncomesController),
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
            PasswordHash = "not-used-in-income-tests",
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync();
        return user;
    }

    private static CreateIncomeRequest CreateRequest(
        decimal amount = 1_000,
        string? description = "Test income",
        DateOnly? date = null) =>
        new()
        {
            Amount = amount,
            Description = description,
            Date = date ?? new DateOnly(2026, 8, 16)
        };

    private static Income NewIncome(
        Guid id,
        Guid userId,
        DateOnly date,
        DateTime createdAt) =>
        new()
        {
            Id = id,
            UserId = userId,
            Amount = 100,
            Description = id.ToString(),
            Date = date,
            CreatedAt = createdAt
        };
}
