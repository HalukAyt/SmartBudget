using System.ComponentModel.DataAnnotations;

namespace SmartBudget.Api.DTOs.Auth;

public sealed class LoginRequest
{
    [Required]
    public string Email { get; init; } = string.Empty;

    [Required]
    public string Password { get; init; } = string.Empty;
}
