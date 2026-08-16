using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;
using SmartBudget.Api.Common;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.Bills;
using SmartBudget.Api.Entities;
using SmartBudget.Api.Enums;

namespace SmartBudget.Api.Services;

public sealed class BillService(
    AppDbContext dbContext,
    TimeProvider timeProvider)
{
    private const string IstanbulTimeZoneId = "Europe/Istanbul";
    private static readonly BillType[] SupportedBillTypes = Enum.GetValues<BillType>();

    public async Task<BillResponse> CreateAsync(
        Guid authenticatedUserId,
        CreateBillRequest request,
        CancellationToken cancellationToken = default)
    {
        ValidateBillType(request.BillType);

        if (request.Amount <= 0)
        {
            throw new ValidationException("Amount must be greater than zero.");
        }

        if (request.ConsumptionValue is <= 0)
        {
            throw new ValidationException(
                "ConsumptionValue must be greater than zero when provided.");
        }

        if (request.BillingDate == default)
        {
            throw new ValidationException("BillingDate is required.");
        }

        var billCategoryExists = await dbContext.Categories
            .AsNoTracking()
            .AnyAsync(
                category => category.Id == SeedCategoryIds.Bill,
                cancellationToken);

        if (!billCategoryExists)
        {
            throw new ValidationException("The seeded bill category is unavailable.");
        }

        var createdAt = DateTime.UtcNow;

        var bill = new Bill
        {
            Id = Guid.NewGuid(),
            UserId = authenticatedUserId,
            BillType = request.BillType,
            Amount = request.Amount,
            ConsumptionValue = request.ConsumptionValue,
            BillingDate = request.BillingDate,
            CreatedAt = createdAt
        };

        var expense = new Expense
        {
            Id = Guid.NewGuid(),
            UserId = authenticatedUserId,
            Amount = request.Amount,
            Description = GetExpenseDescription(request.BillType),
            CategoryId = SeedCategoryIds.Bill,
            Date = request.BillingDate,
            CreatedAt = createdAt,
            IsAiCategorized = false,
            BillId = bill.Id
        };

        await using var transaction = dbContext.Database.IsRelational()
            ? await dbContext.Database.BeginTransactionAsync(cancellationToken)
            : null;

        dbContext.Bills.Add(bill);
        dbContext.Expenses.Add(expense);
        await dbContext.SaveChangesAsync(cancellationToken);

        if (transaction is not null)
        {
            await transaction.CommitAsync(cancellationToken);
        }

        return ToResponse(bill);
    }

    public async Task<IReadOnlyList<BillListItemResponse>> GetAllAsync(
        Guid authenticatedUserId,
        CancellationToken cancellationToken = default)
    {
        return await dbContext.Bills
            .AsNoTracking()
            .Where(bill => bill.UserId == authenticatedUserId)
            .OrderByDescending(bill => bill.BillingDate)
            .ThenByDescending(bill => bill.CreatedAt)
            .ThenByDescending(bill => bill.Id)
            .Select(bill => new BillListItemResponse(
                bill.Id,
                bill.BillType,
                bill.Amount,
                bill.ConsumptionValue,
                bill.BillType == BillType.Electricity ? "kWh" : "m³",
                bill.BillingDate,
                bill.CreatedAt))
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<BillTrendResponse>> GetTrendsAsync(
        Guid authenticatedUserId,
        CancellationToken cancellationToken = default)
    {
        var currentMonth = GetCurrentIstanbulMonth();
        var firstMonth = currentMonth.AddMonths(-5);
        var exclusiveEnd = currentMonth.AddMonths(1);

        var aggregates = await dbContext.Bills
            .AsNoTracking()
            .Where(bill =>
                bill.UserId == authenticatedUserId &&
                bill.BillingDate >= firstMonth &&
                bill.BillingDate < exclusiveEnd)
            .GroupBy(bill => new
            {
                bill.BillingDate.Year,
                bill.BillingDate.Month,
                bill.BillType
            })
            .Select(group => new BillTrendAggregate(
                group.Key.Year,
                group.Key.Month,
                group.Key.BillType,
                group.Sum(bill => bill.Amount),
                group.Any(bill => bill.ConsumptionValue.HasValue),
                group.Sum(bill => bill.ConsumptionValue ?? 0)))
            .ToListAsync(cancellationToken);

        var aggregateLookup = aggregates.ToDictionary(
            aggregate => (aggregate.Year, aggregate.Month, aggregate.BillType));
        var response = new List<BillTrendResponse>(6 * SupportedBillTypes.Length);

        for (var offset = 0; offset < 6; offset++)
        {
            var month = firstMonth.AddMonths(offset);

            foreach (var billType in SupportedBillTypes)
            {
                aggregateLookup.TryGetValue(
                    (month.Year, month.Month, billType),
                    out var aggregate);

                response.Add(new BillTrendResponse(
                    month.Year,
                    month.Month,
                    billType,
                    aggregate?.TotalAmount ?? 0,
                    aggregate is { HasConsumption: true }
                        ? aggregate.TotalConsumption
                        : null,
                    GetConsumptionUnit(billType)));
            }
        }

        return response;
    }

    public async Task DeleteAsync(
        Guid authenticatedUserId,
        Guid billId,
        CancellationToken cancellationToken = default)
    {
        var bill = await dbContext.Bills.SingleOrDefaultAsync(
            candidate =>
                candidate.Id == billId &&
                candidate.UserId == authenticatedUserId,
            cancellationToken);

        if (bill is null)
        {
            throw BillNotFound();
        }

        var linkedExpense = await dbContext.Expenses.SingleOrDefaultAsync(
            expense =>
                expense.BillId == bill.Id &&
                expense.UserId == authenticatedUserId,
            cancellationToken);

        await using var transaction = dbContext.Database.IsRelational()
            ? await dbContext.Database.BeginTransactionAsync(cancellationToken)
            : null;

        if (linkedExpense is not null)
        {
            dbContext.Expenses.Remove(linkedExpense);
        }

        dbContext.Bills.Remove(bill);
        await dbContext.SaveChangesAsync(cancellationToken);

        if (transaction is not null)
        {
            await transaction.CommitAsync(cancellationToken);
        }
    }

    private DateOnly GetCurrentIstanbulMonth()
    {
        var istanbulTimeZone = TimeZoneInfo.FindSystemTimeZoneById(IstanbulTimeZoneId);
        var istanbulNow = TimeZoneInfo.ConvertTime(
            timeProvider.GetUtcNow(),
            istanbulTimeZone);

        return new DateOnly(istanbulNow.Year, istanbulNow.Month, 1);
    }

    private static BillResponse ToResponse(Bill bill) =>
        new(
            bill.Id,
            bill.BillType,
            bill.Amount,
            bill.ConsumptionValue,
            GetConsumptionUnit(bill.BillType),
            bill.BillingDate,
            bill.CreatedAt);

    private static string GetConsumptionUnit(BillType billType) =>
        billType switch
        {
            BillType.Electricity => "kWh",
            BillType.Water or BillType.NaturalGas => "m³",
            _ => throw new ValidationException("BillType is invalid.")
        };

    private static string GetExpenseDescription(BillType billType) =>
        billType switch
        {
            BillType.Electricity => "Elektrik faturası",
            BillType.Water => "Su faturası",
            BillType.NaturalGas => "Doğalgaz faturası",
            _ => throw new ValidationException("BillType is invalid.")
        };

    private static void ValidateBillType(BillType billType)
    {
        if (!Enum.IsDefined(billType))
        {
            throw new ValidationException("BillType is invalid.");
        }
    }

    private static NotFoundException BillNotFound() =>
        new("Bill was not found.");

    private sealed record BillTrendAggregate(
        int Year,
        int Month,
        BillType BillType,
        decimal TotalAmount,
        bool HasConsumption,
        decimal TotalConsumption);
}
