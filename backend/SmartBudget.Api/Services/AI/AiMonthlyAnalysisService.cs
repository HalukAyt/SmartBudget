using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;
using SmartBudget.Api.DTOs.AI;
using SmartBudget.Api.DTOs.Dashboard;
using SmartBudget.Api.Services;

namespace SmartBudget.Api.Services.AI;

public sealed class AiMonthlyAnalysisService(
    DashboardService dashboardService,
    IAiMonthlyAnalysisClient client,
    ILogger<AiMonthlyAnalysisService> logger)
{
    public const int MaxAnalysisLength = 1200;
    private const string NoDataAnalysis =
        "Bu ay için henüz yeterli finansal veri bulunmuyor.";

    private static readonly string[] ForbiddenAdvicePhrases =
    {
        "yatırım yap",
        "satın al",
        "hisse öner",
        "kripto öner",
        "fon öner",
        "para transfer",
        "ödeme yap"
    };

    private static readonly JsonSerializerOptions SummaryJsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    private static readonly Regex NumericTokenPattern = new(
        @"(?<![\p{L}\p{N}])[-+]?\d+(?:[.,]\d+)*(?![\p{L}\p{N}])",
        RegexOptions.Compiled | RegexOptions.CultureInvariant);

    private static readonly string[] InternalFieldNames =
    {
        "year",
        "month",
        "totalIncome",
        "totalExpense",
        "balance",
        "categoryExpenses",
        "budgetUsages",
        "previousMonthExpenseChangePercent",
        "highestSpendingCategory",
        "highestIncreaseCategory",
        "lastSixMonthsTrend",
        "categoryName",
        "amount",
        "percentageOfTotalExpense",
        "limitAmount",
        "spentAmount",
        "usagePercent",
        "alertStatus",
        "increaseAmount"
    };

    private static readonly Regex TechnicalTermPattern = new(
        @"(?<![\p{L}\p{N}_])(?:null|undefined|N/A|DTO|payload|field|property|backend|JSON|Warning|Exceeded)(?![\p{L}\p{N}_])",
        RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);

    private static readonly Regex JsonKeyValuePattern = new(
        "[\"'][A-Za-z_][A-Za-z0-9_]*[\"']\\s*:",
        RegexOptions.Compiled | RegexOptions.CultureInvariant);

    public async Task<MonthlyAnalysisResponse> AnalyzeAsync(
        Guid authenticatedUserId,
        MonthlyAnalysisRequest request,
        CancellationToken cancellationToken = default)
    {
        var dashboard = await dashboardService.GetMonthlyAsync(
            authenticatedUserId,
            request.Year,
            request.Month,
            cancellationToken);

        if (dashboard.TotalIncome == 0 && dashboard.TotalExpense == 0)
        {
            return new MonthlyAnalysisResponse(
                true,
                dashboard.Year,
                dashboard.Month,
                NoDataAnalysis,
                false,
                "No financial activity was available for analysis.");
        }

        var summaryJson = JsonSerializer.Serialize(
            CreateSummary(dashboard),
            SummaryJsonOptions);

        string? rawResponse;

        try
        {
            rawResponse = await client.AnalyzeAsync(summaryJson, cancellationToken);
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            logger.LogWarning("AI monthly analysis timed out.");
            return Fallback(dashboard, "AI monthly analysis is temporarily unavailable.");
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            logger.LogWarning(
                "AI monthly analysis failed with {ErrorType}.",
                exception.GetType().Name);
            return Fallback(dashboard, "AI monthly analysis is temporarily unavailable.");
        }

        if (string.IsNullOrWhiteSpace(rawResponse))
        {
            return Fallback(dashboard, "AI did not return a usable analysis.");
        }

        RawMonthlyAnalysisResponse? parsed;

        try
        {
            parsed = JsonSerializer.Deserialize<RawMonthlyAnalysisResponse>(rawResponse);
        }
        catch (JsonException)
        {
            return Fallback(dashboard, "AI did not return a usable analysis.");
        }

        var analysis = parsed?.Analysis?.Trim();

        if (!IsValidAnalysis(analysis, dashboard))
        {
            return Fallback(
                dashboard,
                "AI analizi güvenli biçimde oluşturulamadı. Lütfen daha sonra tekrar deneyin.");
        }

        return new MonthlyAnalysisResponse(
            true,
            dashboard.Year,
            dashboard.Month,
            analysis,
            false,
            "Monthly analysis is available.");
    }

    private static MonthlyAnalysisSummary CreateSummary(MonthlyDashboardResponse dashboard) =>
        new(
            dashboard.Year,
            dashboard.Month,
            dashboard.TotalIncome,
            dashboard.TotalExpense,
            dashboard.Balance,
            dashboard.CategoryExpenses
                .Select(category => new CategoryAnalysisSummary(
                    category.CategoryName,
                    category.Amount,
                    category.PercentageOfTotalExpense))
                .ToList(),
            dashboard.BudgetUsages
                .Select(budget => new BudgetAnalysisSummary(
                    budget.Category.Name,
                    budget.LimitAmount,
                    budget.SpentAmount,
                    budget.UsagePercent,
                    budget.AlertStatus.ToString()))
                .ToList(),
            dashboard.PreviousMonthExpenseChangePercent,
            dashboard.HighestSpendingCategory?.CategoryName,
            dashboard.HighestIncreaseCategory is null
                ? null
                : new IncreaseAnalysisSummary(
                    dashboard.HighestIncreaseCategory.CategoryName,
                    dashboard.HighestIncreaseCategory.IncreaseAmount));

    private static bool IsValidAnalysis(
        string? analysis,
        MonthlyDashboardResponse dashboard)
    {
        if (string.IsNullOrWhiteSpace(analysis) ||
            analysis.Length > MaxAnalysisLength ||
            analysis.StartsWith('{'))
        {
            return false;
        }

        if (ForbiddenAdvicePhrases.Any(phrase =>
            analysis.Contains(phrase, StringComparison.OrdinalIgnoreCase)))
        {
            return false;
        }

        if (ContainsTechnicalLeakage(analysis))
        {
            return false;
        }

        var allowedNumbers = CreateAllowedNumbers(dashboard);

        return NumericTokenPattern.Matches(analysis)
            .Select(match => match.Value)
            .All(token => ParseNumericCandidates(token).Any(allowedNumbers.Contains));
    }

    private static bool ContainsTechnicalLeakage(string analysis) =>
        analysis.Contains('{') ||
        analysis.Contains('}') ||
        JsonKeyValuePattern.IsMatch(analysis) ||
        TechnicalTermPattern.IsMatch(analysis) ||
        InternalFieldNames.Any(fieldName =>
            analysis.Contains(fieldName, StringComparison.OrdinalIgnoreCase));

    private static HashSet<decimal> CreateAllowedNumbers(MonthlyDashboardResponse dashboard)
    {
        var allowedNumbers = new HashSet<decimal>
        {
            dashboard.TotalIncome,
            dashboard.TotalExpense,
            dashboard.Balance
        };

        foreach (var category in dashboard.CategoryExpenses)
        {
            allowedNumbers.Add(category.Amount);
            allowedNumbers.Add(category.PercentageOfTotalExpense);
        }

        foreach (var budget in dashboard.BudgetUsages)
        {
            allowedNumbers.Add(budget.LimitAmount);
            allowedNumbers.Add(budget.SpentAmount);
            allowedNumbers.Add(budget.UsagePercent);
        }

        if (dashboard.PreviousMonthExpenseChangePercent is { } previousMonthChange)
        {
            allowedNumbers.Add(previousMonthChange);
        }

        if (dashboard.HighestSpendingCategory is { } highestSpendingCategory)
        {
            allowedNumbers.Add(highestSpendingCategory.Amount);
        }

        if (dashboard.HighestIncreaseCategory is { } highestIncreaseCategory)
        {
            allowedNumbers.Add(highestIncreaseCategory.IncreaseAmount);
        }

        return allowedNumbers;
    }

    private static IEnumerable<decimal> ParseNumericCandidates(string token)
    {
        var candidates = new HashSet<decimal>();
        var dotIndex = token.LastIndexOf('.');
        var commaIndex = token.LastIndexOf(',');

        if (dotIndex >= 0 && commaIndex >= 0)
        {
            var decimalSeparator = dotIndex > commaIndex ? '.' : ',';
            var groupingSeparator = decimalSeparator == '.' ? ',' : '.';
            AddCandidate(
                candidates,
                token.Replace(groupingSeparator.ToString(), string.Empty)
                    .Replace(decimalSeparator, '.'));
            return candidates;
        }

        var separatorIndex = Math.Max(dotIndex, commaIndex);
        if (separatorIndex >= 0)
        {
            AddCandidate(candidates, token.Replace(',', '.'));

            if (token.Length - separatorIndex - 1 == 3)
            {
                AddCandidate(candidates, token.Remove(separatorIndex, 1));
            }

            return candidates;
        }

        AddCandidate(candidates, token);
        return candidates;
    }

    private static void AddCandidate(HashSet<decimal> candidates, string normalizedToken)
    {
        if (decimal.TryParse(
            normalizedToken,
            NumberStyles.AllowLeadingSign | NumberStyles.AllowDecimalPoint,
            CultureInfo.InvariantCulture,
            out var value))
        {
            candidates.Add(value);
        }
    }

    private static MonthlyAnalysisResponse Fallback(
        MonthlyDashboardResponse dashboard,
        string message) =>
        new(false, dashboard.Year, dashboard.Month, null, true, message);
}

internal sealed record RawMonthlyAnalysisResponse(
    [property: JsonPropertyName("analysis")] string? Analysis);

internal sealed record MonthlyAnalysisSummary(
    int Year,
    int Month,
    decimal TotalIncome,
    decimal TotalExpense,
    decimal Balance,
    IReadOnlyList<CategoryAnalysisSummary> CategoryExpenses,
    IReadOnlyList<BudgetAnalysisSummary> BudgetUsages,
    decimal? PreviousMonthExpenseChangePercent,
    string? HighestSpendingCategory,
    IncreaseAnalysisSummary? HighestIncreaseCategory);

internal sealed record CategoryAnalysisSummary(
    string CategoryName,
    decimal Amount,
    decimal PercentageOfTotalExpense);

internal sealed record BudgetAnalysisSummary(
    string CategoryName,
    decimal LimitAmount,
    decimal SpentAmount,
    decimal UsagePercent,
    string AlertStatus);

internal sealed record IncreaseAnalysisSummary(
    string CategoryName,
    decimal IncreaseAmount);
