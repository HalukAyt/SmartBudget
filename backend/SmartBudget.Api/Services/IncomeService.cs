using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;
using SmartBudget.Api.Common;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.Incomes;
using SmartBudget.Api.Entities;

namespace SmartBudget.Api.Services;

public sealed class IncomeService(AppDbContext dbContext)
{
    public async Task<IncomeResponse> CreateAsync(
        Guid authenticatedUserId,
        CreateIncomeRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.Amount <= 0)
        {
            throw new ValidationException("Amount must be greater than zero.");
        }

        if (request.Date == default)
        {
            throw new ValidationException("Date is required.");
        }

        var description = string.IsNullOrWhiteSpace(request.Description)
            ? null
            : request.Description.Trim();

        var income = new Income
        {
            Id = Guid.NewGuid(),
            UserId = authenticatedUserId,
            Amount = request.Amount,
            Description = description,
            Date = request.Date,
            CreatedAt = DateTime.UtcNow
        };

        dbContext.Incomes.Add(income);
        await dbContext.SaveChangesAsync(cancellationToken);

        return ToResponse(income);
    }

    public async Task<IReadOnlyList<IncomeListItemResponse>> GetAllAsync(
        Guid authenticatedUserId,
        CancellationToken cancellationToken = default)
    {
        return await dbContext.Incomes
            .AsNoTracking()
            .Where(income => income.UserId == authenticatedUserId)
            .OrderByDescending(income => income.Date)
            .ThenByDescending(income => income.CreatedAt)
            .ThenByDescending(income => income.Id)
            .Select(income => new IncomeListItemResponse(
                income.Id,
                income.Amount,
                income.Description,
                income.Date,
                income.CreatedAt))
            .ToListAsync(cancellationToken);
    }

    public async Task DeleteAsync(
        Guid authenticatedUserId,
        Guid incomeId,
        CancellationToken cancellationToken = default)
    {
        var income = await dbContext.Incomes.SingleOrDefaultAsync(
            candidate =>
                candidate.Id == incomeId &&
                candidate.UserId == authenticatedUserId,
            cancellationToken);

        if (income is null)
        {
            throw IncomeNotFound();
        }

        dbContext.Incomes.Remove(income);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private static IncomeResponse ToResponse(Income income) =>
        new(
            income.Id,
            income.Amount,
            income.Description,
            income.Date,
            income.CreatedAt);

    private static NotFoundException IncomeNotFound() =>
        new("Income was not found.");
}
