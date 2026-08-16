using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.Extensions.Options;

namespace SmartBudget.Api.Services.AI;

public sealed class OpenAiMonthlyAnalysisClient(
    HttpClient httpClient,
    IOptions<AiOptions> options) : IAiMonthlyAnalysisClient
{
    internal const string Instructions = """
        Yalnızca <trusted_backend_summary> içindeki backend tarafından hesaplanmış verileri kullan.
        Finansal değerleri yeniden hesaplama, değiştirme veya eksik veriyi tahmin etme.
        Sistemde olmayan rakam, olay ya da gelecek tahmini üretme.
        Yatırım tavsiyesi verme; hisse, kripto, fon veya başka yatırım ürünü önerme.
        Satın alma, ödeme ya da para transferi talimatı verme.
        Yalnızca verilen kategori yoğunluklarını, önceki ay değişimini ve Warning/Exceeded bütçe durumlarını yorumla.
        Suçlayıcı, korkutucu veya aşırı kesin dil kullanma.
        Kısa ve anlaşılır Türkçe yaz. Yalnızca özette açıkça verilen sayısal değerleri aynen kullan; yeni sayı türetme veya hesaplama.
        Kullanıcıya yalnızca doğal ve kullanıcı dostu Türkçe anlatım sun.
        JSON alan adlarını, camelCase/PascalCase property adlarını veya ham anahtar/değer çiftlerini metne yazma.
        null, undefined, N/A, DTO, payload, field, property, backend veya JSON gibi teknik ifadeleri kullanıcıya gösterme.
        Eksik ya da null bir bilgi varsa bunu atla veya "karşılaştırma verisi bulunmuyor" gibi doğal Türkçe ile anlat.
        Warning/Exceeded gibi enum değerlerini aynen yazma; durumu "limite yaklaşıldı" veya "bütçe aşıldı" şeklinde doğal Türkçe anlat.
        Yalnızca istenen JSON şemasını döndür.
        """;

    private readonly AiOptions _options = options.Value;

    public async Task<string?> AnalyzeAsync(
        string dashboardSummaryJson,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_options.ApiKey))
        {
            throw new InvalidOperationException("AI API key is not configured.");
        }

        using var request = new HttpRequestMessage(HttpMethod.Post, _options.BaseUrl);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _options.ApiKey);
        request.Content = JsonContent.Create(new
        {
            model = _options.Model,
            store = false,
            instructions = Instructions,
            input = new[]
            {
                new
                {
                    role = "user",
                    content = new[]
                    {
                        new
                        {
                            type = "input_text",
                            text = $"<trusted_backend_summary>{dashboardSummaryJson}</trusted_backend_summary>"
                        }
                    }
                }
            },
            text = new
            {
                format = new
                {
                    type = "json_schema",
                    name = "monthly_financial_analysis",
                    strict = true,
                    schema = new
                    {
                        type = "object",
                        properties = new
                        {
                            analysis = new
                            {
                                type = "string",
                                minLength = 1,
                                maxLength = AiMonthlyAnalysisService.MaxAnalysisLength
                            }
                        },
                        required = new[] { "analysis" },
                        additionalProperties = false
                    }
                }
            }
        });

        using var response = await httpClient.SendAsync(request, cancellationToken);
        response.EnsureSuccessStatusCode();

        var envelope = await response.Content.ReadFromJsonAsync<OpenAiResponseEnvelope>(
            cancellationToken: cancellationToken);

        return envelope?.Output
            .SelectMany(item => item.Content)
            .FirstOrDefault(content => content.Type == "output_text")
            ?.Text;
    }
}
