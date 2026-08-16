namespace SmartBudget.Api.Services.AI;

public sealed class AiOptions
{
    public const string SectionName = "AI";

    public string ApiKey { get; init; } = string.Empty;
    public string Model { get; init; } = string.Empty;
    public string BaseUrl { get; init; } = string.Empty;
    public int TimeoutSeconds { get; init; } = 15;
}
