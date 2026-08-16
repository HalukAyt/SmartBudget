using System.ComponentModel.DataAnnotations;
using System.Net;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using SmartBudget.Api.Controllers;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.AI;
using SmartBudget.Api.Entities;
using SmartBudget.Api.Services;
using SmartBudget.Api.Services.AI;

namespace SmartBudget.Api.Tests.AI;

public sealed class AiMonthlyAnalysisServiceTests : IAsyncDisposable
{
    private readonly AppDbContext _dbContext;
    private readonly DashboardService _dashboardService;

    public AiMonthlyAnalysisServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        _dbContext = new AppDbContext(options);
        _dbContext.Database.EnsureCreated();
        _dashboardService = new DashboardService(
            _dbContext,
            new FixedTimeProvider(
                new DateTimeOffset(2026, 8, 16, 9, 0, 0, TimeSpan.Zero)));
    }

    [Fact]
    public async Task Missing_period_uses_dashboard_europe_istanbul_current_month()
    {
        var dashboard = new DashboardService(
            _dbContext,
            new FixedTimeProvider(
                new DateTimeOffset(2026, 8, 31, 21, 30, 0, TimeSpan.Zero)));
        var client = new FakeClient((string?)null);
        var service = CreateService(client, dashboard);
        var user = await AddUserAsync();

        var response = await service.AnalyzeAsync(user.Id, new MonthlyAnalysisRequest());

        Assert.Equal(2026, response.Year);
        Assert.Equal(9, response.Month);
        Assert.True(response.Success);
        Assert.Equal(0, client.CallCount);
    }

    [Fact]
    public async Task Explicit_period_is_preserved_in_success_response()
    {
        var client = new FakeClient("""{"analysis":"Harcamalar market kategorisinde yoğunlaşıyor."}""");
        var service = CreateService(client);
        var user = await AddUserAsync();
        await AddIncomeAsync(user.Id, 100, new DateOnly(2025, 12, 1));

        var response = await service.AnalyzeAsync(user.Id, new MonthlyAnalysisRequest
        {
            Year = 2025,
            Month = 12
        });

        Assert.True(response.Success);
        Assert.Equal(2025, response.Year);
        Assert.Equal(12, response.Month);
        Assert.Equal("Harcamalar market kategorisinde yoğunlaşıyor.", response.Analysis);
    }

    [Theory]
    [InlineData(2026, null)]
    [InlineData(null, 8)]
    [InlineData(2026, 0)]
    [InlineData(2026, 13)]
    [InlineData(1999, 8)]
    [InlineData(2101, 8)]
    public async Task Invalid_period_is_rejected_by_dashboard_rules(int? year, int? month)
    {
        var service = CreateService(new FakeClient((string?)null));
        var user = await AddUserAsync();

        await Assert.ThrowsAsync<ValidationException>(() =>
            service.AnalyzeAsync(user.Id, new MonthlyAnalysisRequest
            {
                Year = year,
                Month = month
            }));
    }

    [Fact]
    public async Task Dashboard_result_is_the_source_of_ai_summary_and_user_is_isolated()
    {
        var client = new FakeClient("""{"analysis":"Gelir giderden yüksek görünüyor."}""");
        var service = CreateService(client);
        var user = await AddUserAsync();
        var otherUser = await AddUserAsync();
        var market = await GetCategoryAsync("Market");
        await AddIncomeAsync(user.Id, 1_000, new DateOnly(2026, 8, 1));
        await AddExpenseAsync(user.Id, market.Id, 250, new DateOnly(2026, 8, 1));
        await AddIncomeAsync(otherUser.Id, 9_000, new DateOnly(2026, 8, 1));

        await service.AnalyzeAsync(user.Id, RequestForAugust());

        using var summary = JsonDocument.Parse(client.ReceivedSummary!);
        Assert.Equal(1_000, summary.RootElement.GetProperty("totalIncome").GetDecimal());
        Assert.Equal(250, summary.RootElement.GetProperty("totalExpense").GetDecimal());
        Assert.Equal(750, summary.RootElement.GetProperty("balance").GetDecimal());
    }

    [Fact]
    public async Task Ai_summary_contains_only_calculated_minimum_data()
    {
        var client = new FakeClient("""{"analysis":"Market harcamaları dikkat çekiyor."}""");
        var service = CreateService(client);
        var user = await AddUserAsync();
        var market = await GetCategoryAsync("Market");
        await AddExpenseAsync(user.Id, market.Id, 100, new DateOnly(2026, 8, 1));

        await service.AnalyzeAsync(user.Id, RequestForAugust());

        var summary = client.ReceivedSummary!;
        Assert.DoesNotContain(user.Id.ToString(), summary);
        Assert.DoesNotContain(user.Email, summary);
        Assert.DoesNotContain(user.PasswordHash, summary);
        Assert.DoesNotContain("Dashboard test expense", summary);
        Assert.DoesNotContain("JWT", summary, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("lastSixMonthsTrend", summary);
        Assert.Contains("categoryExpenses", summary);
        Assert.Contains("budgetUsages", summary);
    }

    [Fact]
    public async Task Empty_financial_data_skips_ai_and_returns_deterministic_analysis()
    {
        var client = new FakeClient(new InvalidOperationException("must not be called"));
        var service = CreateService(client);
        var user = await AddUserAsync();

        var response = await service.AnalyzeAsync(user.Id, RequestForAugust());

        Assert.True(response.Success);
        Assert.Equal("Bu ay için henüz yeterli finansal veri bulunmuyor.", response.Analysis);
        Assert.False(response.RequiresManualReview);
        Assert.Equal(0, client.CallCount);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("not-json")]
    [InlineData("{}")]
    [InlineData("""{"analysis":null}""")]
    [InlineData("""{"analysis":"   "}""")]
    public async Task Missing_empty_or_invalid_analysis_returns_controlled_fallback(
        string? rawResponse)
    {
        var service = CreateService(new FakeClient(rawResponse));
        var user = await AddUserAsync();
        await AddIncomeAsync(user.Id, 100, new DateOnly(2026, 8, 1));

        var response = await service.AnalyzeAsync(user.Id, RequestForAugust());

        Assert.False(response.Success);
        Assert.Null(response.Analysis);
        Assert.True(response.RequiresManualReview);
    }

    [Theory]
    [InlineData("timeout")]
    [InlineData("http")]
    [InlineData("configuration")]
    public async Task Provider_errors_return_controlled_fallback(string error)
    {
        Exception exception = error switch
        {
            "timeout" => new TaskCanceledException("timeout"),
            "http" => new HttpRequestException("provider detail"),
            _ => new InvalidOperationException("secret configuration detail")
        };
        var service = CreateService(new FakeClient(exception));
        var user = await AddUserAsync();
        await AddIncomeAsync(user.Id, 100, new DateOnly(2026, 8, 1));

        var response = await service.AnalyzeAsync(user.Id, RequestForAugust());

        Assert.False(response.Success);
        Assert.Null(response.Analysis);
        Assert.DoesNotContain("provider detail", response.Message);
        Assert.DoesNotContain("secret configuration detail", response.Message);
    }

    [Theory]
    [InlineData("Hisse satın al ve yatırım yap.")]
    [InlineData("{raw provider envelope}")]
    public async Task Investment_advice_or_raw_analysis_is_rejected(string analysis)
    {
        var service = CreateService(new FakeClient(
            JsonSerializer.Serialize(new { analysis })));
        var user = await AddUserAsync();
        await AddIncomeAsync(user.Id, 100, new DateOnly(2026, 8, 1));

        var response = await service.AnalyzeAsync(user.Id, RequestForAugust());

        Assert.False(response.Success);
        Assert.Null(response.Analysis);
    }

    [Theory]
    [InlineData("Önceki aya ilişkin gider değişimi bilgisi yok (previousMonthExpenseChangePercent: null).")]
    [InlineData("Bu ay totalExpense alanı dikkat çekiyor.")]
    [InlineData("AlertStatus: Exceeded")]
    [InlineData("CategoryExpenses verisi mevcut.")]
    [InlineData("DTO içindeki property değeri null.")]
    public async Task Internal_field_or_technical_term_leakage_is_rejected(string analysis)
    {
        var service = CreateService(new FakeClient(
            JsonSerializer.Serialize(new { analysis })));
        var user = await AddUserAsync();
        await AddIncomeAsync(user.Id, 100, new DateOnly(2026, 8, 1));

        var response = await service.AnalyzeAsync(user.Id, RequestForAugust());

        Assert.False(response.Success);
        Assert.Null(response.Analysis);
        Assert.True(response.RequiresManualReview);
        Assert.DoesNotContain(analysis, response.Message);
    }

    [Fact]
    public async Task Json_like_analysis_is_rejected_without_exposing_raw_output()
    {
        const string analysis = "Finansal özet: {\"totalIncome\":100}";
        var service = CreateService(new FakeClient(
            JsonSerializer.Serialize(new { analysis })));
        var user = await AddUserAsync();
        await AddIncomeAsync(user.Id, 100, new DateOnly(2026, 8, 1));

        var response = await service.AnalyzeAsync(user.Id, RequestForAugust());

        Assert.False(response.Success);
        Assert.Null(response.Analysis);
        Assert.DoesNotContain("totalIncome", response.Message);
    }

    [Fact]
    public async Task Natural_turkish_missing_comparison_message_is_accepted_when_input_is_null()
    {
        const string analysis = "Önceki aya ait karşılaştırma verisi bulunmuyor.";
        var client = new FakeClient(JsonSerializer.Serialize(new { analysis }));
        var service = CreateService(client);
        var user = await AddUserAsync();
        var market = await GetCategoryAsync("Market");
        await AddExpenseAsync(user.Id, market.Id, 100, new DateOnly(2026, 8, 1));

        var response = await service.AnalyzeAsync(user.Id, RequestForAugust());

        using var summary = JsonDocument.Parse(client.ReceivedSummary!);
        Assert.Equal(
            JsonValueKind.Null,
            summary.RootElement.GetProperty("previousMonthExpenseChangePercent").ValueKind);
        Assert.True(response.Success);
        Assert.Equal(analysis, response.Analysis);
    }

    [Fact]
    public async Task Amount_from_backend_summary_is_allowed_in_analysis()
    {
        const string analysis = "Toplam gelir 1.500,50 TL olarak görünüyor.";
        var service = CreateService(new FakeClient(JsonSerializer.Serialize(new { analysis })));
        var user = await AddUserAsync();
        await AddIncomeAsync(user.Id, 1_500.50m, new DateOnly(2026, 8, 1));

        var response = await service.AnalyzeAsync(user.Id, RequestForAugust());

        Assert.True(response.Success);
        Assert.Equal(analysis, response.Analysis);
    }

    [Fact]
    public async Task Percentage_from_backend_summary_is_allowed_in_analysis()
    {
        const string analysis = "Market harcamaları toplam giderin %80 değerine ulaşıyor.";
        var service = CreateService(new FakeClient(JsonSerializer.Serialize(new { analysis })));
        var user = await AddUserAsync();
        var market = await GetCategoryAsync("Market");
        var rent = await GetCategoryAsync("Kira");
        await AddExpenseAsync(user.Id, market.Id, 80, new DateOnly(2026, 8, 1));
        await AddExpenseAsync(user.Id, rent.Id, 20, new DateOnly(2026, 8, 1));

        var response = await service.AnalyzeAsync(user.Id, RequestForAugust());

        Assert.True(response.Success);
        Assert.Equal(analysis, response.Analysis);
    }

    [Fact]
    public async Task Invariant_decimal_from_backend_summary_is_allowed_in_analysis()
    {
        const string analysis = "Toplam gelir 1500.50 TL olarak görünüyor.";
        var service = CreateService(new FakeClient(JsonSerializer.Serialize(new { analysis })));
        var user = await AddUserAsync();
        await AddIncomeAsync(user.Id, 1_500.50m, new DateOnly(2026, 8, 1));

        var response = await service.AnalyzeAsync(user.Id, RequestForAugust());

        Assert.True(response.Success);
        Assert.Equal(analysis, response.Analysis);
    }

    [Fact]
    public async Task Number_not_present_in_backend_summary_is_rejected()
    {
        const string analysis = "Toplam gelir 999 TL olarak görünüyor.";
        var service = CreateService(new FakeClient(JsonSerializer.Serialize(new { analysis })));
        var user = await AddUserAsync();
        await AddIncomeAsync(user.Id, 100, new DateOnly(2026, 8, 1));

        var response = await service.AnalyzeAsync(user.Id, RequestForAugust());

        Assert.False(response.Success);
        Assert.Null(response.Analysis);
        Assert.True(response.RequiresManualReview);
    }

    [Fact]
    public async Task Excessively_long_analysis_is_rejected()
    {
        var analysis = new string('a', AiMonthlyAnalysisService.MaxAnalysisLength + 1);
        var service = CreateService(new FakeClient(JsonSerializer.Serialize(new { analysis })));
        var user = await AddUserAsync();
        await AddIncomeAsync(user.Id, 100, new DateOnly(2026, 8, 1));

        var response = await service.AnalyzeAsync(user.Id, RequestForAugust());

        Assert.False(response.Success);
    }

    [Fact]
    public async Task Openai_prompt_forbids_recalculation_hallucination_and_investment_advice()
    {
        var handler = new CapturingHandler(new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(
                """{"output":[{"content":[{"type":"output_text","text":"{\"analysis\":\"Harcamalar market kategorisinde yoğunlaşıyor.\"}"}]}]}""",
                Encoding.UTF8,
                "application/json")
        });
        var client = new OpenAiMonthlyAnalysisClient(
            new HttpClient(handler),
            Options.Create(new AiOptions
            {
                ApiKey = "test-secret",
                Model = "test-model",
                BaseUrl = "https://example.test/v1/responses"
            }));

        await client.AnalyzeAsync("{\"totalIncome\":100}");

        using var payload = JsonDocument.Parse(handler.RequestBody);
        var instructions = payload.RootElement.GetProperty("instructions").GetString()!;
        var input = payload.RootElement.GetProperty("input")[0]
            .GetProperty("content")[0].GetProperty("text").GetString()!;
        Assert.Contains("Yalnızca <trusted_backend_summary>", instructions);
        Assert.Contains("yeniden hesaplama", instructions);
        Assert.Contains("olmayan rakam", instructions);
        Assert.Contains("Yatırım tavsiyesi verme", instructions);
        Assert.Contains("hisse, kripto, fon", instructions);
        Assert.Contains("özette açıkça verilen sayısal değerleri aynen kullan", instructions);
        Assert.Contains("doğal ve kullanıcı dostu Türkçe", instructions);
        Assert.Contains("JSON alan adlarını", instructions);
        Assert.Contains("null, undefined, N/A", instructions);
        Assert.Contains("enum değerlerini aynen yazma", instructions);
        Assert.DoesNotContain("analiz metninde rakam kullanma", instructions);
        Assert.Contains("<trusted_backend_summary>", input);
        Assert.Contains("\"totalIncome\":100", input);
    }

    [Fact]
    public async Task Monthly_analysis_does_not_modify_financial_tables()
    {
        var service = CreateService(new FakeClient(
            "{\"analysis\":\"Gelirler giderlerden yüksek görünüyor.\"}"));
        var user = await AddUserAsync();
        await AddIncomeAsync(user.Id, 100, new DateOnly(2026, 8, 1));
        var before = await GetFinancialCountsAsync();

        await service.AnalyzeAsync(user.Id, RequestForAugust());

        Assert.Equal(before, await GetFinancialCountsAsync());
    }

    [Fact]
    public void Monthly_analysis_contract_has_no_user_id_secret_or_raw_response()
    {
        var requestProperties = typeof(MonthlyAnalysisRequest).GetProperties();
        var responseProperties = typeof(MonthlyAnalysisResponse).GetProperties();

        Assert.DoesNotContain(requestProperties, property => property.Name == "UserId");
        Assert.DoesNotContain(responseProperties, property => property.Name == "ApiKey");
        Assert.DoesNotContain(responseProperties, property => property.Name == "RawResponse");
    }

    [Fact]
    public void Monthly_summary_controller_requires_authentication_and_returns_dto()
    {
        Assert.NotNull(Attribute.GetCustomAttribute(
            typeof(AiController),
            typeof(AuthorizeAttribute)));
        var method = typeof(AiController).GetMethod(nameof(AiController.MonthlySummary))!;
        Assert.Contains(
            typeof(MonthlyAnalysisResponse),
            method.ReturnType.GenericTypeArguments[0].GenericTypeArguments);
    }

    public async ValueTask DisposeAsync() => await _dbContext.DisposeAsync();

    private AiMonthlyAnalysisService CreateService(
        IAiMonthlyAnalysisClient client,
        DashboardService? dashboardService = null) =>
        new(
            dashboardService ?? _dashboardService,
            client,
            NullLogger<AiMonthlyAnalysisService>.Instance);

    private async Task<User> AddUserAsync()
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = $"{Guid.NewGuid()}@example.com",
            PasswordHash = "dashboard-ai-test-hash",
            CreatedAt = DateTime.UtcNow
        };
        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync();
        return user;
    }

    private Task<Category> GetCategoryAsync(string name) =>
        _dbContext.Categories.SingleAsync(category => category.Name == name);

    private async Task AddIncomeAsync(Guid userId, decimal amount, DateOnly date)
    {
        _dbContext.Incomes.Add(new Income
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Amount = amount,
            Date = date,
            CreatedAt = DateTime.UtcNow
        });
        await _dbContext.SaveChangesAsync();
    }

    private async Task AddExpenseAsync(
        Guid userId,
        Guid categoryId,
        decimal amount,
        DateOnly date)
    {
        _dbContext.Expenses.Add(new Expense
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            CategoryId = categoryId,
            Amount = amount,
            Description = "Dashboard test expense",
            Date = date,
            CreatedAt = DateTime.UtcNow
        });
        await _dbContext.SaveChangesAsync();
    }

    private async Task<(int Expenses, int Incomes, int Budgets, int Bills)> GetFinancialCountsAsync() =>
        (
            await _dbContext.Expenses.CountAsync(),
            await _dbContext.Incomes.CountAsync(),
            await _dbContext.Budgets.CountAsync(),
            await _dbContext.Bills.CountAsync());

    private static MonthlyAnalysisRequest RequestForAugust() =>
        new() { Year = 2026, Month = 8 };

    private sealed class FakeClient : IAiMonthlyAnalysisClient
    {
        private readonly string? _response;
        private readonly Exception? _exception;

        public FakeClient(string? response) => _response = response;
        public FakeClient(Exception exception) => _exception = exception;

        public int CallCount { get; private set; }
        public string? ReceivedSummary { get; private set; }

        public Task<string?> AnalyzeAsync(
            string dashboardSummaryJson,
            CancellationToken cancellationToken = default)
        {
            CallCount++;
            ReceivedSummary = dashboardSummaryJson;
            return _exception is null
                ? Task.FromResult(_response)
                : Task.FromException<string?>(_exception);
        }
    }

    private sealed class CapturingHandler(HttpResponseMessage response) : HttpMessageHandler
    {
        public string RequestBody { get; private set; } = string.Empty;

        protected override async Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            RequestBody = await request.Content!.ReadAsStringAsync(cancellationToken);
            return response;
        }
    }

    private sealed class FixedTimeProvider(DateTimeOffset utcNow) : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => utcNow;
    }
}
