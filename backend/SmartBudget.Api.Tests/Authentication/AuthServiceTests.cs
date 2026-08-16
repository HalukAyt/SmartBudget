using System.ComponentModel.DataAnnotations;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SmartBudget.Api.Authentication;
using SmartBudget.Api.Common;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.Auth;
using SmartBudget.Api.Entities;
using SmartBudget.Api.Services;

namespace SmartBudget.Api.Tests.Authentication;

public sealed class AuthServiceTests : IAsyncDisposable
{
    private const string TestPassword = "safe-password-123";
    private const string TestSigningKey =
        "test-only-signing-key-with-at-least-thirty-two-bytes";

    private readonly AppDbContext _dbContext;
    private readonly AuthService _authService;
    private readonly JwtOptions _jwtOptions;

    public AuthServiceTests()
    {
        var dbOptions = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _dbContext = new AppDbContext(dbOptions);
        _jwtOptions = new JwtOptions
        {
            Issuer = "SmartBudget.Api.Tests",
            Audience = "SmartBudget.Api.Tests.Client",
            Key = TestSigningKey,
            ExpirationMinutes = JwtOptions.RequiredExpirationMinutes
        };

        var passwordHasher = new PasswordHasher<User>();
        var jwtTokenService = new JwtTokenService(Options.Create(_jwtOptions));
        _authService = new AuthService(_dbContext, passwordHasher, jwtTokenService);
    }

    [Fact]
    public async Task Register_with_valid_input_creates_user_with_normalized_email_and_utc_timestamp()
    {
        var beforeRegistration = DateTime.UtcNow;

        await RegisterUserAsync("  USER@Example.COM  ");

        var user = await _dbContext.Users.SingleAsync();
        Assert.NotEqual(Guid.Empty, user.Id);
        Assert.Equal("user@example.com", user.Email);
        Assert.True(user.CreatedAt >= beforeRegistration);
        Assert.Equal(DateTimeKind.Utc, user.CreatedAt.Kind);
    }

    [Fact]
    public async Task Register_with_duplicate_normalized_email_is_rejected()
    {
        await RegisterUserAsync("user@example.com");

        await Assert.ThrowsAsync<ConflictException>(() =>
            RegisterUserAsync(" USER@EXAMPLE.COM "));
    }

    [Fact]
    public async Task Register_with_password_shorter_than_eight_characters_is_rejected()
    {
        var request = new RegisterRequest
        {
            Email = "user@example.com",
            Password = "short"
        };

        await Assert.ThrowsAsync<ValidationException>(() =>
            _authService.RegisterAsync(request));
    }

    [Fact]
    public async Task Register_does_not_store_plain_text_password()
    {
        await RegisterUserAsync("user@example.com");

        var user = await _dbContext.Users.SingleAsync();
        Assert.NotEqual(TestPassword, user.PasswordHash);
        Assert.DoesNotContain(TestPassword, user.PasswordHash, StringComparison.Ordinal);
    }

    [Fact]
    public async Task Login_with_valid_credentials_returns_access_token_and_limited_user_data()
    {
        await RegisterUserAsync("user@example.com");

        var response = await _authService.LoginAsync(new LoginRequest
        {
            Email = " USER@EXAMPLE.COM ",
            Password = TestPassword
        });

        var user = await _dbContext.Users.SingleAsync();
        Assert.False(string.IsNullOrWhiteSpace(response.AccessToken));
        Assert.Equal(user.Id, response.UserId);
        Assert.Equal(user.Email, response.Email);
    }

    [Fact]
    public async Task Login_with_invalid_password_is_rejected_with_generic_error()
    {
        await RegisterUserAsync("user@example.com");

        var exception = await Assert.ThrowsAsync<InvalidCredentialsException>(() =>
            _authService.LoginAsync(new LoginRequest
            {
                Email = "user@example.com",
                Password = "wrong-password"
            }));

        Assert.Equal("Email or password is invalid.", exception.Message);
    }

    [Fact]
    public async Task Login_token_contains_user_id_claim_and_expires_in_about_sixty_minutes()
    {
        await RegisterUserAsync("user@example.com");
        var user = await _dbContext.Users.SingleAsync();
        var response = await _authService.LoginAsync(new LoginRequest
        {
            Email = user.Email,
            Password = TestPassword
        });

        var token = new JwtSecurityTokenHandler().ReadJwtToken(response.AccessToken);
        var subject = token.Claims.Single(claim => claim.Type == JwtRegisteredClaimNames.Sub);
        var nameIdentifier = token.Claims.Single(
            claim => claim.Type == ClaimTypes.NameIdentifier);
        var lifetime = token.ValidTo - token.ValidFrom;

        Assert.Equal(user.Id.ToString(), subject.Value);
        Assert.Equal(user.Id.ToString(), nameIdentifier.Value);
        Assert.InRange(lifetime, TimeSpan.FromMinutes(59), TimeSpan.FromMinutes(61));
        Assert.Equal(_jwtOptions.Issuer, token.Issuer);
        Assert.Contains(_jwtOptions.Audience, token.Audiences);
    }

    [Fact]
    public async Task Login_token_does_not_contain_password_or_password_hash()
    {
        await RegisterUserAsync("user@example.com");
        var user = await _dbContext.Users.SingleAsync();
        var response = await _authService.LoginAsync(new LoginRequest
        {
            Email = user.Email,
            Password = TestPassword
        });

        var token = new JwtSecurityTokenHandler().ReadJwtToken(response.AccessToken);

        Assert.DoesNotContain(token.Claims, claim =>
            claim.Type.Contains("password", StringComparison.OrdinalIgnoreCase));
        Assert.DoesNotContain(token.Claims, claim => claim.Value == TestPassword);
        Assert.DoesNotContain(token.Claims, claim => claim.Value == user.PasswordHash);
    }

    public async ValueTask DisposeAsync()
    {
        await _dbContext.DisposeAsync();
    }

    private Task RegisterUserAsync(string email) =>
        _authService.RegisterAsync(new RegisterRequest
        {
            Email = email,
            Password = TestPassword
        });
}
