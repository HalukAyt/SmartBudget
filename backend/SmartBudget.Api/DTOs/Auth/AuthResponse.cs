namespace SmartBudget.Api.DTOs.Auth;

public sealed record AuthResponse(
    string AccessToken,
    Guid UserId,
    string Email);
