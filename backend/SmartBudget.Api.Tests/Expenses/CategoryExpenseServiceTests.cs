using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using SmartBudget.Api.Common;
using SmartBudget.Api.Controllers;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.Categories;
using SmartBudget.Api.DTOs.Expenses;
using SmartBudget.Api.Entities;
using SmartBudget.Api.Enums;
using SmartBudget.Api.Services;

namespace SmartBudget.Api.Tests.Expenses;

public sealed class CategoryExpenseServiceTests : IAsyncDisposable
{
    private readonly AppDbContext _dbContext;
    private readonly CategoryService _categoryService;
    private readonly ExpenseService _expenseService;

    public CategoryExpenseServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _dbContext = new AppDbContext(options);
        _dbContext.Database.EnsureCreated();
        _categoryService = new CategoryService(_dbContext);
        _expenseService = new ExpenseService(_dbContext);
    }

    [Fact]
    public async Task Category_list_returns_eight_seed_categories_as_dtos()
    {
        var categories = await _categoryService.GetAllAsync();

        Assert.Equal(8, categories.Count);
        Assert.All(categories, category => Assert.IsType<CategoryResponse>(category));
        Assert.Equal(
            new[]
            {
                "Diğer",
                "Eğitim",
                "Eğlence",
                "Fatura",
                "Kira",
                "Market",
                "Sağlık",
                "Ulaşım"
            },
            categories.Select(category => category.Name));
    }

    [Fact]
    public void Category_and_expense_controllers_require_authentication()
    {
        Assert.NotNull(Attribute.GetCustomAttribute(
            typeof(CategoriesController),
            typeof(AuthorizeAttribute)));
        Assert.NotNull(Attribute.GetCustomAttribute(
            typeof(ExpensesController),
            typeof(AuthorizeAttribute)));
    }

    [Fact]
    public async Task Create_with_valid_input_returns_dto_and_persists_trimmed_expense()
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");

        var response = await _expenseService.CreateAsync(
            user.Id,
            CreateRequest(category.Id, description: "  Weekly groceries  "));

        var storedExpense = await _dbContext.Expenses.SingleAsync();
        Assert.IsType<ExpenseResponse>(response);
        Assert.IsType<CategoryResponse>(response.Category);
        Assert.Equal(storedExpense.Id, response.Id);
        Assert.Equal("Weekly groceries", storedExpense.Description);
        Assert.Equal("Weekly groceries", response.Description);
        Assert.Equal(category.Id, response.Category.Id);
        Assert.Equal("Market", response.Category.Name);
        Assert.Equal(DateTimeKind.Utc, response.CreatedAt.Kind);
    }

    [Fact]
    public async Task Create_assigns_authenticated_user_id_and_request_has_no_user_id()
    {
        var authenticatedUser = await AddUserAsync();
        var category = await GetCategoryAsync("Ulaşım");

        await _expenseService.CreateAsync(
            authenticatedUser.Id,
            CreateRequest(category.Id));

        var storedExpense = await _dbContext.Expenses.SingleAsync();
        Assert.Equal(authenticatedUser.Id, storedExpense.UserId);
        Assert.DoesNotContain(
            typeof(CreateExpenseRequest).GetProperties(),
            property => property.Name == "UserId");
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public async Task Create_rejects_non_positive_amount(decimal amount)
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        var request = CreateRequest(category.Id, amount: amount);

        await Assert.ThrowsAsync<ValidationException>(() =>
            _expenseService.CreateAsync(user.Id, request));

        Assert.Empty(_dbContext.Expenses);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    public async Task Create_rejects_empty_or_whitespace_description(string description)
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        var request = CreateRequest(category.Id, description: description);

        await Assert.ThrowsAsync<ValidationException>(() =>
            _expenseService.CreateAsync(user.Id, request));

        Assert.Empty(_dbContext.Expenses);
    }

    [Fact]
    public async Task Create_rejects_invalid_category_id()
    {
        var user = await AddUserAsync();
        var request = CreateRequest(Guid.NewGuid());

        await Assert.ThrowsAsync<ValidationException>(() =>
            _expenseService.CreateAsync(user.Id, request));

        Assert.Empty(_dbContext.Expenses);
    }

    [Fact]
    public async Task Create_rejects_missing_date()
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        var request = new CreateExpenseRequest
        {
            Amount = 100,
            Description = "Groceries",
            CategoryId = category.Id,
            Date = default
        };

        await Assert.ThrowsAsync<ValidationException>(() =>
            _expenseService.CreateAsync(user.Id, request));
    }

    [Fact]
    public async Task Create_stores_and_returns_is_ai_categorized_without_affecting_category_validation()
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Eğlence");
        var request = CreateRequest(category.Id, isAiCategorized: true);

        var response = await _expenseService.CreateAsync(user.Id, request);

        var storedExpense = await _dbContext.Expenses.SingleAsync();
        Assert.True(storedExpense.IsAiCategorized);
        Assert.True(response.IsAiCategorized);
        Assert.Equal(category.Id, storedExpense.CategoryId);
    }

    [Fact]
    public async Task List_returns_only_authenticated_users_expenses()
    {
        var authenticatedUser = await AddUserAsync();
        var otherUser = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        await _expenseService.CreateAsync(
            authenticatedUser.Id,
            CreateRequest(category.Id, description: "Mine"));
        await _expenseService.CreateAsync(
            otherUser.Id,
            CreateRequest(category.Id, description: "Not mine"));

        var expenses = await _expenseService.GetAllAsync(authenticatedUser.Id);

        var expense = Assert.Single(expenses);
        Assert.Equal("Mine", expense.Description);
        Assert.IsType<ExpenseListItemResponse>(expense);
    }

    [Fact]
    public async Task List_is_deterministically_ordered_by_date_created_at_and_id_descending()
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Market");
        var firstId = Guid.Parse("00000000-0000-0000-0000-000000000101");
        var secondId = Guid.Parse("00000000-0000-0000-0000-000000000102");
        var newestDateId = Guid.Parse("00000000-0000-0000-0000-000000000103");

        _dbContext.Expenses.AddRange(
            NewExpense(
                firstId,
                user.Id,
                category.Id,
                new DateOnly(2026, 1, 1),
                new DateTime(2026, 1, 1, 10, 0, 0, DateTimeKind.Utc)),
            NewExpense(
                secondId,
                user.Id,
                category.Id,
                new DateOnly(2026, 1, 1),
                new DateTime(2026, 1, 1, 11, 0, 0, DateTimeKind.Utc)),
            NewExpense(
                newestDateId,
                user.Id,
                category.Id,
                new DateOnly(2026, 2, 1),
                new DateTime(2026, 1, 1, 9, 0, 0, DateTimeKind.Utc)));
        await _dbContext.SaveChangesAsync();
        _dbContext.ChangeTracker.Clear();

        var expenses = await _expenseService.GetAllAsync(user.Id);

        Assert.Equal(
            new[] { newestDateId, secondId, firstId },
            expenses.Select(expense => expense.Id));
        Assert.Empty(_dbContext.ChangeTracker.Entries<Expense>());
    }

    [Fact]
    public async Task Detail_returns_expense_only_to_owner_as_dto()
    {
        var owner = await AddUserAsync();
        var category = await GetCategoryAsync("Sağlık");
        var created = await _expenseService.CreateAsync(
            owner.Id,
            CreateRequest(category.Id));

        var detail = await _expenseService.GetByIdAsync(owner.Id, created.Id);

        Assert.IsType<ExpenseResponse>(detail);
        Assert.Equal(created, detail);
    }

    [Fact]
    public async Task Detail_for_other_users_expense_returns_same_not_found_error()
    {
        var owner = await AddUserAsync();
        var otherUser = await AddUserAsync();
        var category = await GetCategoryAsync("Eğitim");
        var created = await _expenseService.CreateAsync(
            owner.Id,
            CreateRequest(category.Id));

        var exception = await Assert.ThrowsAsync<NotFoundException>(() =>
            _expenseService.GetByIdAsync(otherUser.Id, created.Id));

        Assert.Equal("Expense was not found.", exception.Message);
    }

    [Fact]
    public async Task Detail_for_missing_expense_returns_not_found()
    {
        var user = await AddUserAsync();

        await Assert.ThrowsAsync<NotFoundException>(() =>
            _expenseService.GetByIdAsync(user.Id, Guid.NewGuid()));
    }

    [Fact]
    public async Task Delete_allows_owner_and_removed_expense_no_longer_appears_in_list()
    {
        var owner = await AddUserAsync();
        var category = await GetCategoryAsync("Fatura");
        var created = await _expenseService.CreateAsync(
            owner.Id,
            CreateRequest(category.Id));

        await _expenseService.DeleteAsync(owner.Id, created.Id);

        Assert.Empty(await _expenseService.GetAllAsync(owner.Id));
        Assert.False(await _dbContext.Expenses.AnyAsync(
            expense => expense.Id == created.Id));
    }

    [Fact]
    public async Task Delete_for_other_users_expense_returns_not_found_and_preserves_expense()
    {
        var owner = await AddUserAsync();
        var otherUser = await AddUserAsync();
        var category = await GetCategoryAsync("Kira");
        var created = await _expenseService.CreateAsync(
            owner.Id,
            CreateRequest(category.Id));

        var exception = await Assert.ThrowsAsync<NotFoundException>(() =>
            _expenseService.DeleteAsync(otherUser.Id, created.Id));

        Assert.Equal("Expense was not found.", exception.Message);
        Assert.True(await _dbContext.Expenses.AnyAsync(
            expense => expense.Id == created.Id));
    }

    [Fact]
    public async Task Manual_expense_has_no_bill_link()
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Fatura");

        await _expenseService.CreateAsync(user.Id, CreateRequest(category.Id));

        Assert.Null((await _dbContext.Expenses.SingleAsync()).BillId);
    }

    [Fact]
    public async Task Delete_rejects_bill_linked_expense_and_preserves_it()
    {
        var user = await AddUserAsync();
        var category = await GetCategoryAsync("Fatura");
        var bill = new Bill
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            BillType = BillType.Electricity,
            Amount = 200,
            BillingDate = new DateOnly(2026, 8, 16),
            CreatedAt = DateTime.UtcNow
        };
        var expense = NewExpense(
            Guid.NewGuid(),
            user.Id,
            category.Id,
            bill.BillingDate,
            DateTime.UtcNow);
        expense.BillId = bill.Id;
        _dbContext.AddRange(bill, expense);
        await _dbContext.SaveChangesAsync();

        var exception = await Assert.ThrowsAsync<ConflictException>(() =>
            _expenseService.DeleteAsync(user.Id, expense.Id));

        Assert.Equal(
            "Faturadan oluşturulan gider, Faturalar bölümünden silinmelidir.",
            exception.Message);
        Assert.True(await _dbContext.Expenses.AnyAsync(
            candidate => candidate.Id == expense.Id));
        Assert.True(await _dbContext.Bills.AnyAsync(
            candidate => candidate.Id == bill.Id));
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
            PasswordHash = "not-used-in-expense-tests",
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync();
        return user;
    }

    private Task<Category> GetCategoryAsync(string name) =>
        _dbContext.Categories.SingleAsync(category => category.Name == name);

    private static CreateExpenseRequest CreateRequest(
        Guid categoryId,
        decimal amount = 100,
        string description = "Test expense",
        bool isAiCategorized = false) =>
        new()
        {
            Amount = amount,
            Description = description,
            CategoryId = categoryId,
            Date = new DateOnly(2026, 8, 16),
            IsAiCategorized = isAiCategorized
        };

    private static Expense NewExpense(
        Guid id,
        Guid userId,
        Guid categoryId,
        DateOnly date,
        DateTime createdAt) =>
        new()
        {
            Id = id,
            UserId = userId,
            Amount = 100,
            Description = id.ToString(),
            CategoryId = categoryId,
            Date = date,
            CreatedAt = createdAt,
            IsAiCategorized = false
        };
}
