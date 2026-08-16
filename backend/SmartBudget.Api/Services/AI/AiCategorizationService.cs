using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.AI;

namespace SmartBudget.Api.Services.AI;

public sealed class AiCategorizationService(
    AppDbContext dbContext,
    IAiCategorizationClient client,
    ILogger<AiCategorizationService> logger)
{
    public static readonly string[] AllowedCategories =
    {
        "Market",
        "Ulaşım",
        "Fatura",
        "Eğlence",
        "Sağlık",
        "Eğitim",
        "Kira",
        "Diğer"
    };

    private static readonly HashSet<string> CategoryWhitelist =
        new(AllowedCategories, StringComparer.Ordinal);

    public async Task<CategorizeExpenseResponse> CategorizeAsync(
        CategorizeExpenseRequest request,
        CancellationToken cancellationToken = default)
    {
        var description = request.Description?.Trim();

        if (string.IsNullOrWhiteSpace(description))
        {
            throw new ValidationException("Description is required.");
        }

        string? rawResponse;

        try
        {
            rawResponse = await client.CategorizeAsync(description, cancellationToken);
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            logger.LogWarning("AI expense categorization timed out.");
            return Fallback("AI categorization is temporarily unavailable.");
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            logger.LogWarning(
                "AI expense categorization failed with {ErrorType}.",
                exception.GetType().Name);
            return Fallback("AI categorization is temporarily unavailable.");
        }

        if (string.IsNullOrWhiteSpace(rawResponse))
        {
            return Fallback("AI did not return a usable category.");
        }

        RawCategorizationResponse? parsed;

        try
        {
            parsed = JsonSerializer.Deserialize<RawCategorizationResponse>(rawResponse);
        }
        catch (JsonException)
        {
            return Fallback("AI did not return a usable category.");
        }

        if (parsed?.Category is null || !CategoryWhitelist.Contains(parsed.Category))
        {
            return Fallback("AI did not return an allowed category.");
        }

        var category = await dbContext.Categories
            .AsNoTracking()
            .Where(candidate => candidate.Name == parsed.Category)
            .Select(candidate => new { candidate.Id, candidate.Name })
            .SingleOrDefaultAsync(cancellationToken);

        if (category is null)
        {
            return Fallback("The suggested category is not available.");
        }

        return new CategorizeExpenseResponse(
            true,
            category.Id,
            category.Name,
            GetValidConfidence(parsed.Confidence),
            false,
            "A category suggestion is available. You may accept or change it.");
    }

    private static decimal? GetValidConfidence(JsonElement? confidence)
    {
        if (confidence is not { ValueKind: JsonValueKind.Number } value ||
            !value.TryGetDecimal(out var parsed) ||
            parsed is < 0 or > 1)
        {
            return null;
        }

        return parsed;
    }

    private static CategorizeExpenseResponse Fallback(string message) =>
        new(false, null, null, null, true, message);
}

internal sealed record RawCategorizationResponse(
    [property: JsonPropertyName("category")] string? Category,
    [property: JsonPropertyName("confidence")] JsonElement? Confidence);
