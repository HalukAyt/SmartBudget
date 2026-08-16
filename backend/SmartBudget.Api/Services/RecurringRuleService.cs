using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Npgsql;
using SmartBudget.Api.Common;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.Bills;
using SmartBudget.Api.DTOs.Categories;
using SmartBudget.Api.DTOs.Expenses;
using SmartBudget.Api.DTOs.Incomes;
using SmartBudget.Api.DTOs.Recurring;
using SmartBudget.Api.Entities;
using SmartBudget.Api.Enums;

namespace SmartBudget.Api.Services;

public sealed class RecurringRuleService(
    AppDbContext dbContext,
    IncomeService incomeService,
    ExpenseService expenseService,
    BillService billService,
    TimeProvider timeProvider,
    ILogger<RecurringRuleService> logger)
{
    private const int MinYear = 2000;
    private const int MaxYear = 2100;
    private const string IstanbulTimeZoneId = "Europe/Istanbul";
    private static readonly int[] AllowedDurationMonths = { 3, 6, 12 };

    public async Task<RecurringRuleResponse> CreateAsync(
        Guid authenticatedUserId,
        CreateRecurringRuleRequest request,
        CancellationToken cancellationToken = default)
    {
        ValidateRecordType(request.RecordType);

        var endDate = ResolveEndDate(
            request.StartDate,
            request.DurationMonths,
            request.EndDate);
        ValidateYear(request.StartDate.Year);
        ValidateYear(endDate.Year);

        CategoryResponse? category = null;

        switch (request.RecordType)
        {
            case RecurringRecordType.Income:
                ValidateRequiredPositiveAmount(request.Amount, "Income rules");
                RejectField(request.CategoryId is not null, "CategoryId is only valid for expense rules.");
                RejectField(request.BillType is not null, "BillType is only valid for bill rules.");
                break;

            case RecurringRecordType.Expense:
                ValidateRequiredPositiveAmount(request.Amount, "Expense rules");
                RejectField(request.BillType is not null, "BillType is only valid for bill rules.");
                if (request.CategoryId is null)
                {
                    throw new ValidationException("CategoryId is required for expense rules.");
                }

                category = await GetCategoryAsync(request.CategoryId.Value, cancellationToken);
                break;

            case RecurringRecordType.Bill:
                RejectField(request.CategoryId is not null, "CategoryId is only valid for expense rules.");
                if (request.BillType is null || !Enum.IsDefined(request.BillType.Value))
                {
                    throw new ValidationException("BillType is required for bill rules.");
                }

                if (request.Amount is <= 0)
                {
                    throw new ValidationException("Amount must be greater than zero when provided.");
                }

                break;
        }

        var rule = new RecurringFinancialRule
        {
            Id = Guid.NewGuid(),
            UserId = authenticatedUserId,
            RecordType = request.RecordType,
            Frequency = RecurringFrequency.Monthly,
            StartDate = request.StartDate,
            EndDate = endDate,
            IsActive = true,
            Amount = request.Amount,
            Description = NormalizeDescription(request.Description),
            CategoryId = request.RecordType == RecurringRecordType.Expense
                ? category!.Id
                : null,
            BillType = request.RecordType == RecurringRecordType.Bill
                ? request.BillType
                : null,
            CreatedAt = DateTime.UtcNow
        };

        dbContext.RecurringFinancialRules.Add(rule);
        await dbContext.SaveChangesAsync(cancellationToken);

        // Create-time immediate realization: if the rule is already due for
        // the current Europe/Istanbul month (e.g. StartDate is today or an
        // earlier day this month), realize it right away instead of making
        // the user wait for the next midnight scheduler run or a backend
        // restart. Reuses the exact same safe path
        // (TryAutoRealizeAsync -> RealizeCoreAsync) as the background
        // scheduler, so duplicate protection, the Bill "amount unknown stays
        // due" rule, and transaction handling all behave identically. A
        // failure here (including a concurrent-realization race resolved as
        // a duplicate-occurrence conflict) must not fail rule creation,
        // which has already been committed — the background scheduler will
        // still pick this rule up at the next Europe/Istanbul midnight.
        var today = GetCurrentIstanbulDate();

        try
        {
            await TryAutoRealizeAsync(rule, today, cancellationToken);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            logger.LogWarning(
                exception,
                "Immediate create-time realization failed for recurring rule {RuleId}; " +
                "the rule was created and will be retried by the background scheduler.",
                rule.Id);
        }

        var currentMonth = GetCurrentIstanbulMonth();
        var isRealizedThisMonth = await IsRealizedInMonthAsync(
            rule.Id,
            currentMonth,
            cancellationToken);

        return ToResponse(
            rule,
            category,
            isRealizedThisMonth,
            ComputeNextDueDate(rule, currentMonth, isRealizedThisMonth));
    }

    public async Task<IReadOnlyList<RecurringRuleResponse>> GetAllAsync(
        Guid authenticatedUserId,
        CancellationToken cancellationToken = default)
    {
        var rules = await dbContext.RecurringFinancialRules
            .AsNoTracking()
            .Include(rule => rule.Category)
            .Where(rule => rule.UserId == authenticatedUserId)
            .OrderByDescending(rule => rule.CreatedAt)
            .ThenBy(rule => rule.Id)
            .ToListAsync(cancellationToken);

        return await BuildResponsesAsync(authenticatedUserId, rules, cancellationToken);
    }

    public async Task<IReadOnlyList<RecurringRuleResponse>> GetDueAsync(
        Guid authenticatedUserId,
        CancellationToken cancellationToken = default)
    {
        var currentMonth = GetCurrentIstanbulMonth();

        var activeRules = await dbContext.RecurringFinancialRules
            .AsNoTracking()
            .Include(rule => rule.Category)
            .Where(rule => rule.UserId == authenticatedUserId && rule.IsActive)
            .ToListAsync(cancellationToken);

        var dueRules = activeRules
            .Where(rule => IsWithinMonth(rule.StartDate, rule.EndDate, currentMonth))
            .OrderBy(rule => rule.RecordType)
            .ThenBy(rule => rule.Id)
            .ToList();

        return await BuildResponsesAsync(authenticatedUserId, dueRules, cancellationToken);
    }

    public async Task<RecurringRuleResponse> UpdateAsync(
        Guid authenticatedUserId,
        Guid ruleId,
        UpdateRecurringRuleRequest request,
        CancellationToken cancellationToken = default)
    {
        var rule = await dbContext.RecurringFinancialRules
            .Include(candidate => candidate.Category)
            .SingleOrDefaultAsync(
                candidate =>
                    candidate.Id == ruleId &&
                    candidate.UserId == authenticatedUserId,
                cancellationToken);

        if (rule is null)
        {
            throw RuleNotFound();
        }

        if (request.EndDate < rule.StartDate)
        {
            throw new ValidationException("EndDate cannot be before StartDate.");
        }

        ValidateYear(request.EndDate.Year);

        CategoryResponse? category = rule.Category is null
            ? null
            : new CategoryResponse(rule.Category.Id, rule.Category.Name);

        switch (rule.RecordType)
        {
            case RecurringRecordType.Income:
                ValidateRequiredPositiveAmount(request.Amount, "Income rules");
                break;

            case RecurringRecordType.Expense:
                ValidateRequiredPositiveAmount(request.Amount, "Expense rules");
                if (request.CategoryId is not null && request.CategoryId != rule.CategoryId)
                {
                    category = await GetCategoryAsync(request.CategoryId.Value, cancellationToken);
                    rule.CategoryId = category.Id;
                }

                break;

            case RecurringRecordType.Bill:
                if (request.Amount is <= 0)
                {
                    throw new ValidationException("Amount must be greater than zero when provided.");
                }

                if (request.BillType is not null)
                {
                    if (!Enum.IsDefined(request.BillType.Value))
                    {
                        throw new ValidationException("BillType is invalid.");
                    }

                    rule.BillType = request.BillType;
                }

                break;
        }

        rule.IsActive = request.IsActive;
        rule.EndDate = request.EndDate;
        rule.Amount = request.Amount;
        rule.Description = NormalizeDescription(request.Description);

        await dbContext.SaveChangesAsync(cancellationToken);

        var currentMonth = GetCurrentIstanbulMonth();
        var isRealizedThisMonth = await IsRealizedInMonthAsync(
            rule.Id,
            currentMonth,
            cancellationToken);

        return ToResponse(
            rule,
            category,
            isRealizedThisMonth,
            ComputeNextDueDate(rule, currentMonth, isRealizedThisMonth));
    }

    public async Task DeleteAsync(
        Guid authenticatedUserId,
        Guid ruleId,
        CancellationToken cancellationToken = default)
    {
        var rule = await dbContext.RecurringFinancialRules.SingleOrDefaultAsync(
            candidate =>
                candidate.Id == ruleId &&
                candidate.UserId == authenticatedUserId,
            cancellationToken);

        if (rule is null)
        {
            throw RuleNotFound();
        }

        dbContext.RecurringFinancialRules.Remove(rule);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    /// <summary>
    /// Manual/fallback realization used by the API endpoint. Normal Flutter
    /// UX no longer requires this for Income/Expense (those auto-realize via
    /// <see cref="RunAutomaticRealizationAsync"/>); it remains the only way
    /// to realize a Bill rule whose template Amount is unknown.
    /// </summary>
    public async Task<RecurringRealizeResponse> RealizeAsync(
        Guid authenticatedUserId,
        Guid ruleId,
        RealizeRecurringRuleRequest request,
        CancellationToken cancellationToken = default)
    {
        ValidateMonth(request.Month);
        ValidateYear(request.Year);
        var targetMonth = new DateOnly(request.Year, request.Month, 1);

        var rule = await dbContext.RecurringFinancialRules.SingleOrDefaultAsync(
            candidate =>
                candidate.Id == ruleId &&
                candidate.UserId == authenticatedUserId,
            cancellationToken);

        if (rule is null)
        {
            throw RuleNotFound();
        }

        if (!rule.IsActive)
        {
            throw new ValidationException("Recurring rule is not active.");
        }

        if (!IsWithinMonth(rule.StartDate, rule.EndDate, targetMonth))
        {
            throw new ValidationException(
                "The requested month is outside the recurring rule's active period.");
        }

        var alreadyRealized = await dbContext.RecurringOccurrences.AnyAsync(
            occurrence =>
                occurrence.RecurringRuleId == rule.Id &&
                occurrence.Year == request.Year &&
                occurrence.Month == request.Month,
            cancellationToken);

        if (alreadyRealized)
        {
            throw DuplicateOccurrence();
        }

        var recordDate = RecurrenceDateHelper.GetOccurrenceDate(
            rule.StartDate,
            request.Year,
            request.Month);

        var createdRecordId = await RealizeCoreAsync(
            rule,
            request.Year,
            request.Month,
            recordDate,
            request.Amount,
            request.ConsumptionValue,
            cancellationToken);

        return new RecurringRealizeResponse(
            rule.RecordType,
            rule.Id,
            createdRecordId,
            request.Year,
            request.Month);
    }

    /// <summary>
    /// Scans every active recurring rule and realizes the ones whose
    /// recurrence day (Europe/Istanbul) has arrived for the current month
    /// and has not been realized yet. Intended to be invoked periodically by
    /// <c>RecurringRuleRealizationHostedService</c>; safe to call repeatedly
    /// (idempotent via the RecurringOccurrence unique constraint) and safe to
    /// call late (catches up same-month misses if the backend was offline on
    /// the exact due day). Bill rules with an unknown (null) template Amount
    /// are intentionally skipped — they stay due until the user enters a
    /// real amount via <see cref="RealizeAsync"/>.
    /// </summary>
    public async Task<int> RunAutomaticRealizationAsync(CancellationToken cancellationToken = default)
    {
        var today = GetCurrentIstanbulDate();

        var activeRules = await dbContext.RecurringFinancialRules
            .Where(rule => rule.IsActive)
            .ToListAsync(cancellationToken);

        var realizedCount = 0;

        foreach (var rule in activeRules)
        {
            try
            {
                if (await TryAutoRealizeAsync(rule, today, cancellationToken))
                {
                    realizedCount++;
                }
            }
            catch (Exception exception) when (exception is not OperationCanceledException)
            {
                logger.LogWarning(
                    exception,
                    "Automatic realization failed for recurring rule {RuleId}.",
                    rule.Id);
            }
        }

        return realizedCount;
    }

    private async Task<bool> TryAutoRealizeAsync(
        RecurringFinancialRule rule,
        DateOnly today,
        CancellationToken cancellationToken)
    {
        var occurrenceDate = RecurrenceDateHelper.GetOccurrenceDate(
            rule.StartDate,
            today.Year,
            today.Month);

        if (occurrenceDate < rule.StartDate || occurrenceDate > rule.EndDate)
        {
            return false;
        }

        if (today < occurrenceDate)
        {
            return false;
        }

        if (rule.RecordType == RecurringRecordType.Bill && rule.Amount is null)
        {
            return false;
        }

        var alreadyRealized = await dbContext.RecurringOccurrences.AnyAsync(
            occurrence =>
                occurrence.RecurringRuleId == rule.Id &&
                occurrence.Year == today.Year &&
                occurrence.Month == today.Month,
            cancellationToken);

        if (alreadyRealized)
        {
            return false;
        }

        await RealizeCoreAsync(
            rule,
            today.Year,
            today.Month,
            occurrenceDate,
            overrideAmount: null,
            consumptionValue: null,
            cancellationToken);

        return true;
    }

    private async Task<Guid> RealizeCoreAsync(
        RecurringFinancialRule rule,
        int year,
        int month,
        DateOnly recordDate,
        decimal? overrideAmount,
        decimal? consumptionValue,
        CancellationToken cancellationToken)
    {
        var occurrence = new RecurringOccurrence
        {
            Id = Guid.NewGuid(),
            RecurringRuleId = rule.Id,
            UserId = rule.UserId,
            Year = year,
            Month = month,
            RecordType = rule.RecordType,
            CreatedRecordId = null,
            CreatedAt = DateTime.UtcNow
        };

        dbContext.RecurringOccurrences.Add(occurrence);

        try
        {
            await dbContext.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException exception) when (IsUniqueConstraintViolation(exception))
        {
            throw DuplicateOccurrence();
        }

        Guid createdRecordId;

        try
        {
            createdRecordId = await CreateRealizedRecordAsync(
                rule.UserId,
                rule,
                overrideAmount,
                consumptionValue,
                recordDate,
                cancellationToken);
        }
        catch
        {
            dbContext.RecurringOccurrences.Remove(occurrence);
            await dbContext.SaveChangesAsync(CancellationToken.None);
            throw;
        }

        occurrence.CreatedRecordId = createdRecordId;
        await dbContext.SaveChangesAsync(cancellationToken);

        return createdRecordId;
    }

    private async Task<Guid> CreateRealizedRecordAsync(
        Guid authenticatedUserId,
        RecurringFinancialRule rule,
        decimal? overrideAmount,
        decimal? consumptionValue,
        DateOnly recordDate,
        CancellationToken cancellationToken)
    {
        switch (rule.RecordType)
        {
            case RecurringRecordType.Income:
            {
                var income = await incomeService.CreateAsync(
                    authenticatedUserId,
                    new CreateIncomeRequest
                    {
                        Amount = rule.Amount!.Value,
                        Description = rule.Description,
                        Date = recordDate
                    },
                    cancellationToken);
                return income.Id;
            }

            case RecurringRecordType.Expense:
            {
                var description = string.IsNullOrWhiteSpace(rule.Description)
                    ? await GetCategoryNameAsync(rule.CategoryId!.Value, cancellationToken)
                    : rule.Description;

                var expense = await expenseService.CreateAsync(
                    authenticatedUserId,
                    new CreateExpenseRequest
                    {
                        Amount = rule.Amount!.Value,
                        Description = description,
                        CategoryId = rule.CategoryId!.Value,
                        Date = recordDate,
                        IsAiCategorized = false
                    },
                    cancellationToken);
                return expense.Id;
            }

            case RecurringRecordType.Bill:
            {
                var amount = overrideAmount ?? rule.Amount;

                if (amount is null or <= 0)
                {
                    throw new ValidationException(
                        "Amount must be provided and greater than zero to realize a bill.");
                }

                var bill = await billService.CreateAsync(
                    authenticatedUserId,
                    new CreateBillRequest
                    {
                        BillType = rule.BillType!.Value,
                        Amount = amount.Value,
                        ConsumptionValue = consumptionValue,
                        BillingDate = recordDate
                    },
                    cancellationToken);
                return bill.Id;
            }

            default:
                throw new ValidationException("RecordType is invalid.");
        }
    }

    private async Task<IReadOnlyList<RecurringRuleResponse>> BuildResponsesAsync(
        Guid authenticatedUserId,
        IReadOnlyList<RecurringFinancialRule> rules,
        CancellationToken cancellationToken)
    {
        if (rules.Count == 0)
        {
            return Array.Empty<RecurringRuleResponse>();
        }

        var currentMonth = GetCurrentIstanbulMonth();
        var ruleIds = rules.Select(rule => rule.Id).ToList();
        var realizedRuleIds = await dbContext.RecurringOccurrences
            .AsNoTracking()
            .Where(occurrence =>
                occurrence.UserId == authenticatedUserId &&
                occurrence.Year == currentMonth.Year &&
                occurrence.Month == currentMonth.Month &&
                ruleIds.Contains(occurrence.RecurringRuleId))
            .Select(occurrence => occurrence.RecurringRuleId)
            .ToListAsync(cancellationToken);
        var realizedSet = realizedRuleIds.ToHashSet();

        return rules
            .Select(rule =>
            {
                var category = rule.Category is null
                    ? null
                    : new CategoryResponse(rule.Category.Id, rule.Category.Name);
                var isRealizedThisMonth = realizedSet.Contains(rule.Id);
                return ToResponse(
                    rule,
                    category,
                    isRealizedThisMonth,
                    ComputeNextDueDate(rule, currentMonth, isRealizedThisMonth));
            })
            .ToList();
    }

    private async Task<bool> IsRealizedInMonthAsync(
        Guid ruleId,
        DateOnly month,
        CancellationToken cancellationToken) =>
        await dbContext.RecurringOccurrences.AsNoTracking().AnyAsync(
            occurrence =>
                occurrence.RecurringRuleId == ruleId &&
                occurrence.Year == month.Year &&
                occurrence.Month == month.Month,
            cancellationToken);

    private async Task<string> GetCategoryNameAsync(
        Guid categoryId,
        CancellationToken cancellationToken) =>
        await dbContext.Categories
            .AsNoTracking()
            .Where(category => category.Id == categoryId)
            .Select(category => category.Name)
            .SingleAsync(cancellationToken);

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

    private DateOnly GetCurrentIstanbulDate()
    {
        var istanbulTimeZone = TimeZoneInfo.FindSystemTimeZoneById(IstanbulTimeZoneId);
        var istanbulNow = TimeZoneInfo.ConvertTime(
            timeProvider.GetUtcNow(),
            istanbulTimeZone);

        return DateOnly.FromDateTime(istanbulNow.DateTime);
    }

    private DateOnly GetCurrentIstanbulMonth()
    {
        var today = GetCurrentIstanbulDate();
        return new DateOnly(today.Year, today.Month, 1);
    }

    private static DateOnly? ComputeNextDueDate(
        RecurringFinancialRule rule,
        DateOnly currentMonth,
        bool isRealizedThisMonth)
    {
        if (!rule.IsActive)
        {
            return null;
        }

        var candidateMonth = isRealizedThisMonth ? currentMonth.AddMonths(1) : currentMonth;
        var startMonth = new DateOnly(rule.StartDate.Year, rule.StartDate.Month, 1);

        if (candidateMonth < startMonth)
        {
            return rule.StartDate;
        }

        var occurrenceDate = RecurrenceDateHelper.GetOccurrenceDate(
            rule.StartDate,
            candidateMonth.Year,
            candidateMonth.Month);

        return occurrenceDate > rule.EndDate ? null : occurrenceDate;
    }

    private static bool IsWithinMonth(DateOnly startDate, DateOnly endDate, DateOnly targetMonth)
    {
        var startMonth = new DateOnly(startDate.Year, startDate.Month, 1);
        var endMonth = new DateOnly(endDate.Year, endDate.Month, 1);
        return startMonth <= targetMonth && endMonth >= targetMonth;
    }

    private static DateOnly ResolveEndDate(
        DateOnly startDate,
        int? durationMonths,
        DateOnly? customEndDate)
    {
        if (durationMonths.HasValue == customEndDate.HasValue)
        {
            throw new ValidationException(
                "Exactly one of DurationMonths or EndDate must be provided.");
        }

        if (durationMonths.HasValue)
        {
            if (!AllowedDurationMonths.Contains(durationMonths.Value))
            {
                throw new ValidationException("DurationMonths must be 3, 6 or 12.");
            }

            return startDate.AddMonths(durationMonths.Value - 1);
        }

        if (customEndDate!.Value < startDate)
        {
            throw new ValidationException("EndDate cannot be before StartDate.");
        }

        return customEndDate.Value;
    }

    private static string? NormalizeDescription(string? description) =>
        string.IsNullOrWhiteSpace(description) ? null : description.Trim();

    private static void ValidateRecordType(RecurringRecordType recordType)
    {
        if (!Enum.IsDefined(recordType))
        {
            throw new ValidationException("RecordType is invalid.");
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
        if (year is < MinYear or > MaxYear)
        {
            throw new ValidationException($"Year must be between {MinYear} and {MaxYear}.");
        }
    }

    private static void ValidateRequiredPositiveAmount(decimal? amount, string context)
    {
        if (amount is null or <= 0)
        {
            throw new ValidationException($"Amount is required and must be greater than zero for {context}.");
        }
    }

    private static void RejectField(bool isPresent, string message)
    {
        if (isPresent)
        {
            throw new ValidationException(message);
        }
    }

    private static bool IsUniqueConstraintViolation(DbUpdateException exception) =>
        exception.InnerException is PostgresException
        {
            SqlState: PostgresErrorCodes.UniqueViolation
        };

    private static RecurringRuleResponse ToResponse(
        RecurringFinancialRule rule,
        CategoryResponse? category,
        bool isRealizedThisMonth,
        DateOnly? nextDueDate) =>
        new(
            rule.Id,
            rule.RecordType,
            rule.Frequency,
            rule.StartDate,
            rule.EndDate,
            rule.IsActive,
            rule.Amount,
            rule.Description,
            category,
            rule.BillType,
            isRealizedThisMonth,
            nextDueDate,
            rule.CreatedAt);

    private static ConflictException DuplicateOccurrence() =>
        new("A record has already been realized for this recurring rule and month.");

    private static NotFoundException RuleNotFound() =>
        new("Recurring rule was not found.");
}
