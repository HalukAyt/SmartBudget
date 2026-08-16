using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;
using SmartBudget.Api.Common;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.Categories;
using SmartBudget.Api.DTOs.Dashboard;

namespace SmartBudget.Api.Services;

public sealed class DashboardService(
    AppDbContext dbContext,
    TimeProvider timeProvider)
{
    private const int MinYear = 2000;
    private const int MaxYear = 2100;
    private const string IstanbulTimeZoneId = "Europe/Istanbul";

    public async Task<MonthlyDashboardResponse> GetMonthlyAsync(
        Guid authenticatedUserId,
        int? year,
        int? month,
        CancellationToken cancellationToken = default)
    {
        var reportMonth = ResolveReportMonth(year, month);
        var reportEnd = reportMonth.AddMonths(1);
        var previousMonth = reportMonth.AddMonths(-1);
        var trendStart = reportMonth.AddMonths(-5);

        var incomeTotals = await dbContext.Incomes
            .AsNoTracking()
            .Where(income =>
                income.UserId == authenticatedUserId &&
                income.Date >= trendStart &&
                income.Date < reportEnd)
            .GroupBy(income => new { income.Date.Year, income.Date.Month })
            .Select(group => new MonthlyTotal(
                group.Key.Year,
                group.Key.Month,
                group.Sum(income => income.Amount)))
            .ToListAsync(cancellationToken);

        var expenseTotals = await dbContext.Expenses
            .AsNoTracking()
            .Where(expense =>
                expense.UserId == authenticatedUserId &&
                expense.Date >= trendStart &&
                expense.Date < reportEnd)
            .GroupBy(expense => new { expense.Date.Year, expense.Date.Month })
            .Select(group => new MonthlyTotal(
                group.Key.Year,
                group.Key.Month,
                group.Sum(expense => expense.Amount)))
            .ToListAsync(cancellationToken);

        var categoryTotals = await dbContext.Expenses
            .AsNoTracking()
            .Where(expense =>
                expense.UserId == authenticatedUserId &&
                expense.Date >= previousMonth &&
                expense.Date < reportEnd)
            .GroupBy(expense => new
            {
                expense.Date.Year,
                expense.Date.Month,
                expense.CategoryId,
                expense.Category.Name
            })
            .Select(group => new CategoryMonthlyTotal(
                group.Key.Year,
                group.Key.Month,
                group.Key.CategoryId,
                group.Key.Name,
                group.Sum(expense => expense.Amount)))
            .ToListAsync(cancellationToken);

        var budgets = await dbContext.Budgets
            .AsNoTracking()
            .Where(budget =>
                budget.UserId == authenticatedUserId &&
                budget.Year == reportMonth.Year &&
                budget.Month == reportMonth.Month)
            .OrderBy(budget => budget.Category.Name)
            .ThenBy(budget => budget.Id)
            .Select(budget => new BudgetValue(
                budget.Id,
                budget.CategoryId,
                budget.Category.Name,
                budget.LimitAmount))
            .ToListAsync(cancellationToken);

        var incomeLookup = incomeTotals.ToDictionary(
            total => (total.Year, total.Month),
            total => total.Amount);
        var expenseLookup = expenseTotals.ToDictionary(
            total => (total.Year, total.Month),
            total => total.Amount);

        var totalIncome = GetTotal(incomeLookup, reportMonth);
        var totalExpense = GetTotal(expenseLookup, reportMonth);
        var previousMonthExpense = GetTotal(expenseLookup, previousMonth);

        var currentCategoryTotals = categoryTotals
            .Where(total =>
                total.Year == reportMonth.Year &&
                total.Month == reportMonth.Month)
            .OrderByDescending(total => total.Amount)
            .ThenBy(total => total.CategoryName)
            .ThenBy(total => total.CategoryId)
            .ToList();

        var categoryExpenses = currentCategoryTotals
            .Select(total => new CategoryExpenseSummary(
                total.CategoryId,
                total.CategoryName,
                total.Amount,
                totalExpense == 0 ? 0 : total.Amount / totalExpense * 100))
            .ToList();

        var currentCategoryLookup = currentCategoryTotals.ToDictionary(
            total => total.CategoryId,
            total => total.Amount);
        var budgetUsages = budgets
            .Select(budget => CreateBudgetUsage(budget, currentCategoryLookup))
            .ToList();

        var highestIncreaseCategory = GetHighestIncreaseCategory(
            categoryTotals,
            reportMonth,
            previousMonth);
        var trend = CreateTrend(
            trendStart,
            incomeLookup,
            expenseLookup);

        return new MonthlyDashboardResponse(
            reportMonth.Year,
            reportMonth.Month,
            totalIncome,
            totalExpense,
            totalIncome - totalExpense,
            categoryExpenses,
            budgetUsages,
            CalculatePreviousMonthChange(totalExpense, previousMonthExpense),
            categoryExpenses.FirstOrDefault(),
            highestIncreaseCategory,
            trend);
    }

    private DateOnly ResolveReportMonth(int? year, int? month)
    {
        if (year.HasValue != month.HasValue)
        {
            throw new ValidationException("Year and month must be provided together.");
        }

        if (year.HasValue)
        {
            ValidateYearAndMonth(year.Value, month!.Value);
            return new DateOnly(year.Value, month.Value, 1);
        }

        var istanbulTimeZone = TimeZoneInfo.FindSystemTimeZoneById(IstanbulTimeZoneId);
        var istanbulNow = TimeZoneInfo.ConvertTime(
            timeProvider.GetUtcNow(),
            istanbulTimeZone);

        return new DateOnly(istanbulNow.Year, istanbulNow.Month, 1);
    }

    private static void ValidateYearAndMonth(int year, int month)
    {
        if (month is < 1 or > 12)
        {
            throw new ValidationException("Month must be between 1 and 12.");
        }

        if (year is < MinYear or > MaxYear)
        {
            throw new ValidationException(
                $"Year must be between {MinYear} and {MaxYear}.");
        }
    }

    private static decimal GetTotal(
        IReadOnlyDictionary<(int Year, int Month), decimal> totals,
        DateOnly month) =>
        totals.GetValueOrDefault((month.Year, month.Month));

    private static BudgetUsageSummary CreateBudgetUsage(
        BudgetValue budget,
        IReadOnlyDictionary<Guid, decimal> currentCategoryTotals)
    {
        var spentAmount = currentCategoryTotals.GetValueOrDefault(budget.CategoryId);
        var usagePercent = BudgetCalculations.CalculateUsagePercent(
            spentAmount,
            budget.LimitAmount);

        return new BudgetUsageSummary(
            budget.Id,
            new CategoryResponse(budget.CategoryId, budget.CategoryName),
            budget.LimitAmount,
            spentAmount,
            usagePercent,
            BudgetCalculations.GetAlertStatus(usagePercent));
    }

    private static decimal? CalculatePreviousMonthChange(
        decimal currentMonthExpense,
        decimal previousMonthExpense)
    {
        if (previousMonthExpense > 0)
        {
            return (currentMonthExpense - previousMonthExpense)
                / previousMonthExpense
                * 100;
        }

        return currentMonthExpense == 0 ? 0 : null;
    }

    private static CategoryIncreaseSummary? GetHighestIncreaseCategory(
        IReadOnlyList<CategoryMonthlyTotal> categoryTotals,
        DateOnly reportMonth,
        DateOnly previousMonth)
    {
        var current = categoryTotals
            .Where(total =>
                total.Year == reportMonth.Year &&
                total.Month == reportMonth.Month)
            .ToDictionary(total => total.CategoryId);
        var previous = categoryTotals
            .Where(total =>
                total.Year == previousMonth.Year &&
                total.Month == previousMonth.Month)
            .ToDictionary(total => total.CategoryId);

        return current.Keys
            .Union(previous.Keys)
            .Select(categoryId =>
            {
                current.TryGetValue(categoryId, out var currentTotal);
                previous.TryGetValue(categoryId, out var previousTotal);
                var source = currentTotal ?? previousTotal!;

                return new CategoryIncreaseSummary(
                    categoryId,
                    source.CategoryName,
                    (currentTotal?.Amount ?? 0) - (previousTotal?.Amount ?? 0));
            })
            .Where(summary => summary.IncreaseAmount > 0)
            .OrderByDescending(summary => summary.IncreaseAmount)
            .ThenBy(summary => summary.CategoryName)
            .ThenBy(summary => summary.CategoryId)
            .FirstOrDefault();
    }

    private static IReadOnlyList<MonthlyTrendPoint> CreateTrend(
        DateOnly trendStart,
        IReadOnlyDictionary<(int Year, int Month), decimal> incomeTotals,
        IReadOnlyDictionary<(int Year, int Month), decimal> expenseTotals)
    {
        var trend = new List<MonthlyTrendPoint>(6);

        for (var offset = 0; offset < 6; offset++)
        {
            var month = trendStart.AddMonths(offset);
            var income = GetTotal(incomeTotals, month);
            var expense = GetTotal(expenseTotals, month);
            trend.Add(new MonthlyTrendPoint(
                month.Year,
                month.Month,
                income,
                expense,
                income - expense));
        }

        return trend;
    }

    private sealed record MonthlyTotal(int Year, int Month, decimal Amount);

    private sealed record CategoryMonthlyTotal(
        int Year,
        int Month,
        Guid CategoryId,
        string CategoryName,
        decimal Amount);

    private sealed record BudgetValue(
        Guid Id,
        Guid CategoryId,
        string CategoryName,
        decimal LimitAmount);
}
