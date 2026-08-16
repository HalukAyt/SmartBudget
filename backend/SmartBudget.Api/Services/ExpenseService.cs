using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;
using SmartBudget.Api.Common;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.Categories;
using SmartBudget.Api.DTOs.Expenses;
using SmartBudget.Api.Entities;

namespace SmartBudget.Api.Services;

public sealed class ExpenseService(AppDbContext dbContext)
{
    public async Task<ExpenseResponse> CreateAsync(
        Guid authenticatedUserId,
        CreateExpenseRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.Amount <= 0)
        {
            throw new ValidationException("Amount must be greater than zero.");
        }

        var description = request.Description?.Trim();

        if (string.IsNullOrWhiteSpace(description))
        {
            throw new ValidationException("Description is required.");
        }

        if (request.Date == default)
        {
            throw new ValidationException("Date is required.");
        }

        var category = await dbContext.Categories
            .AsNoTracking()
            .Where(candidate => candidate.Id == request.CategoryId)
            .Select(candidate => new CategoryResponse(candidate.Id, candidate.Name))
            .SingleOrDefaultAsync(cancellationToken);

        if (category is null)
        {
            throw new ValidationException("CategoryId must reference a valid category.");
        }

        var expense = new Expense
        {
            Id = Guid.NewGuid(),
            UserId = authenticatedUserId,
            Amount = request.Amount,
            Description = description,
            CategoryId = category.Id,
            Date = request.Date,
            CreatedAt = DateTime.UtcNow,
            IsAiCategorized = request.IsAiCategorized
        };

        dbContext.Expenses.Add(expense);
        await dbContext.SaveChangesAsync(cancellationToken);

        return ToResponse(expense, category);
    }

    public async Task<IReadOnlyList<ExpenseListItemResponse>> GetAllAsync(
        Guid authenticatedUserId,
        CancellationToken cancellationToken = default)
    {
        return await dbContext.Expenses
            .AsNoTracking()
            .Where(expense => expense.UserId == authenticatedUserId)
            .OrderByDescending(expense => expense.Date)
            .ThenByDescending(expense => expense.CreatedAt)
            .ThenByDescending(expense => expense.Id)
            .Select(expense => new ExpenseListItemResponse(
                expense.Id,
                expense.Amount,
                expense.Description,
                new CategoryResponse(expense.Category.Id, expense.Category.Name),
                expense.Date,
                expense.CreatedAt,
                expense.IsAiCategorized))
            .ToListAsync(cancellationToken);
    }

    public async Task<ExpenseResponse> GetByIdAsync(
        Guid authenticatedUserId,
        Guid expenseId,
        CancellationToken cancellationToken = default)
    {
        var response = await dbContext.Expenses
            .AsNoTracking()
            .Where(expense =>
                expense.Id == expenseId &&
                expense.UserId == authenticatedUserId)
            .Select(expense => new ExpenseResponse(
                expense.Id,
                expense.Amount,
                expense.Description,
                new CategoryResponse(expense.Category.Id, expense.Category.Name),
                expense.Date,
                expense.CreatedAt,
                expense.IsAiCategorized))
            .SingleOrDefaultAsync(cancellationToken);

        return response ?? throw ExpenseNotFound();
    }

    public async Task DeleteAsync(
        Guid authenticatedUserId,
        Guid expenseId,
        CancellationToken cancellationToken = default)
    {
        var expense = await dbContext.Expenses
            .SingleOrDefaultAsync(
                candidate =>
                    candidate.Id == expenseId &&
                    candidate.UserId == authenticatedUserId,
                cancellationToken);

        if (expense is null)
        {
            throw ExpenseNotFound();
        }

        if (expense.BillId is not null)
        {
            throw new ConflictException(
                "Faturadan oluşturulan gider, Faturalar bölümünden silinmelidir.");
        }

        dbContext.Expenses.Remove(expense);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private static ExpenseResponse ToResponse(
        Expense expense,
        CategoryResponse category) =>
        new(
            expense.Id,
            expense.Amount,
            expense.Description,
            category,
            expense.Date,
            expense.CreatedAt,
            expense.IsAiCategorized);

    private static NotFoundException ExpenseNotFound() =>
        new("Expense was not found.");
}
