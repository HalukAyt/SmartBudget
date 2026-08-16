namespace SmartBudget.Api.Authentication;

public sealed class JwtOptions
{
    public const string SectionName = "Jwt";
    public const int RequiredExpirationMinutes = 60;

    public string Issuer { get; init; } = string.Empty;
    public string Audience { get; init; } = string.Empty;
    public string Key { get; init; } = string.Empty;
    public int ExpirationMinutes { get; init; } = RequiredExpirationMinutes;
}
