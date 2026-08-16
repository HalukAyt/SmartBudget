using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using SmartBudget.Api.Common;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.Budgets;
using SmartBudget.Api.DTOs.Categories;
using SmartBudget.Api.Entities;
using SmartBudget.Api.Enums;

namespace SmartBudget.Api.Services;

public sealed class BudgetService(AppDbContext dbContext)
{
    public async Task<BudgetResponse> CreateAsync(
        Guid authenticatedUserId,
        CreateBudgetRequest request,
        CancellationToken cancellationToken = default)
    {
        ValidateLimitAmount(request.LimitAmount);
        ValidateMonth(request.Month);
        ValidateYear(request.Year);

        var category = await GetCategoryAsync(request.CategoryId, cancellationToken);

        var duplicateExists = await dbContext.Budgets.AnyAsync(
            budget =>
                budget.UserId == authenticatedUserId &&
                budget.CategoryId == request.CategoryId &&
                budget.Month == request.Month &&
                budget.Year == request.Year,
            cancellationToken);

        if (duplicateExists)
        {
            throw DuplicateBudget();
        }

        var budget = new Budget
        {
            Id = Guid.NewGuid(),
            UserId = authenticatedUserId,
            CategoryId = category.Id,
            LimitAmount = request.LimitAmount,
            Month = request.Month,
            Year = request.Year,
            CreatedAt = DateTime.UtcNow
        };

        dbContext.Budgets.Add(budget);

        try
        {
            await dbContext.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException exception) when (IsUniqueConstraintViolation(exception))
        {
            throw DuplicateBudget();
        }

        var spentAmount = await GetSpentAmountAsync(
            authenticatedUserId,
            budget.CategoryId,
            budget.Month,
            budget.Year,
            cancellationToken);

        return ToResponse(budget, category, spentAmount);
    }

    public async Task<IReadOnlyList<BudgetListItemResponse>> GetAllAsync(
        Guid authenticatedUserId,
        CancellationToken cancellationToken = default)
    {
        var values = await BudgetValues(authenticatedUserId)
            .ToListAsync(cancellationToken);

        return values
            .Select(ToListItemResponse)
            .ToList();
    }

    public async Task<BudgetResponse> UpdateAsync(
        Guid authenticatedUserId,
        Guid budgetId,
        UpdateBudgetRequest request,
        CancellationToken cancellationToken = default)
    {
        ValidateLimitAmount(request.LimitAmount);

        var budget = await dbContext.Budgets
            .Include(candidate => candidate.Category)
            .SingleOrDefaultAsync(
                candidate =>
                    candidate.Id == budgetId &&
                    candidate.UserId == authenticatedUserId,
                cancellationToken);

        if (budget is null)
        {
            throw BudgetNotFound();
        }

        budget.LimitAmount = request.LimitAmount;
        await dbContext.SaveChangesAsync(cancellationToken);

        var spentAmount = await GetSpentAmountAsync(
            authenticatedUserId,
            budget.CategoryId,
            budget.Month,
            budget.Year,
            cancellationToken);

        return ToResponse(
            budget,
            new CategoryResponse(budget.Category.Id, budget.Category.Name),
            spentAmount);
    }

    public async Task DeleteAsync(
        Guid authenticatedUserId,
        Guid budgetId,
        CancellationToken cancellationToken = default)
    {
        var budget = await dbContext.Budgets.SingleOrDefaultAsync(
            candidate =>
                candidate.Id == budgetId &&
                candidate.UserId == authenticatedUserId,
            cancellationToken);

        if (budget is null)
        {
            throw BudgetNotFound();
        }

        dbContext.Budgets.Remove(budget);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private IQueryable<BudgetValue> BudgetValues(Guid authenticatedUserId) =>
        dbContext.Budgets
            .AsNoTracking()
            .Where(budget => budget.UserId == authenticatedUserId)
            .OrderByDescending(budget => budget.Year)
            .ThenByDescending(budget => budget.Month)
            .ThenBy(budget => budget.Category.Name)
            .ThenBy(budget => budget.Id)
            .Select(budget => new BudgetValue(
                budget.Id,
                budget.Category.Id,
                budget.Category.Name,
                budget.LimitAmount,
                budget.Month,
                budget.Year,
                dbContext.Expenses
                    .Where(expense =>
                        expense.UserId == authenticatedUserId &&
                        expense.CategoryId == budget.CategoryId &&
                        expense.Date.Month == budget.Month &&
                        expense.Date.Year == budget.Year)
                    .Sum(expense => (decimal?)expense.Amount) ?? 0,
                budget.CreatedAt));

    private async Task<CategoryResponse> GetCategoryAsync(
        Guid categoryId,
        CancellationToken cancellationToken)
    {
        var category = await dbContext.Categories
            .AsNoTracking()
            .Where(candidate => candidate.Id == categoryId)
            .Select(candidate => new CategoryResponse(candidate.Id, candidate.Name))
            .SingleOrDefaultAsync(cancellationToken);

        return category
            ?? throw new ValidationException("CategoryId must reference a valid category.");
    }

    private async Task<decimal> GetSpentAmountAsync(
        Guid authenticatedUserId,
        Guid categoryId,
        int month,
        int year,
        CancellationToken cancellationToken)
    {
        return await dbContext.Expenses
            .AsNoTracking()
            .Where(expense =>
                expense.UserId == authenticatedUserId &&
                expense.CategoryId == categoryId &&
                expense.Date.Month == month &&
                expense.Date.Year == year)
            .SumAsync(expense => (decimal?)expense.Amount, cancellationToken) ?? 0;
    }

    private static BudgetResponse ToResponse(
        Budget budget,
        CategoryResponse category,
        decimal spentAmount)
    {
        var usagePercent = BudgetCalculations.CalculateUsagePercent(
            spentAmount,
            budget.LimitAmount);

        return new BudgetResponse(
            budget.Id,
            category,
            budget.LimitAmount,
            budget.Month,
            budget.Year,
            spentAmount,
            usagePercent,
            BudgetCalculations.GetAlertStatus(usagePercent),
            budget.CreatedAt);
    }

    private static BudgetListItemResponse ToListItemResponse(BudgetValue budget)
    {
        var usagePercent = BudgetCalculations.CalculateUsagePercent(
            budget.SpentAmount,
            budget.LimitAmount);

        return new BudgetListItemResponse(
            budget.Id,
            new CategoryResponse(budget.CategoryId, budget.CategoryName),
            budget.LimitAmount,
            budget.Month,
            budget.Year,
            budget.SpentAmount,
            usagePercent,
            BudgetCalculations.GetAlertStatus(usagePercent),
            budget.CreatedAt);
    }

    private static void ValidateLimitAmount(decimal limitAmount)
    {
        if (limitAmount <= 0)
        {
            throw new ValidationException("LimitAmount must be greater than zero.");
        }
    }

    private static void ValidateMonth(int month)
    {
        if (month is < 1 or > 12)
        {
            throw new ValidationException("Month must be between 1 and 12.");
        }
    }

    private static void ValidateYear(int year)
    {
        if (year is < BudgetValidation.MinYear or > BudgetValidation.MaxYear)
        {
            throw new ValidationException(
                $"Year must be between {BudgetValidation.MinYear} and {BudgetValidation.MaxYear}.");
        }
    }

    private static bool IsUniqueConstraintViolation(DbUpdateException exception) =>
        exception.InnerException is PostgresException
        {
            SqlState: PostgresErrorCodes.UniqueViolation
        };

    private static ConflictException DuplicateBudget() =>
        new("A budget already exists for this category, month and year.");

    private static NotFoundException BudgetNotFound() =>
        new("Budget was not found.");

    private sealed record BudgetValue(
        Guid Id,
        Guid CategoryId,
        string CategoryName,
        decimal LimitAmount,
        int Month,
        int Year,
        decimal SpentAmount,
        DateTime CreatedAt);
}
