using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using SmartBudget.Api.Authentication;
using SmartBudget.Api.Common;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.Auth;
using SmartBudget.Api.Entities;

namespace SmartBudget.Api.Services;

public sealed class AuthService(
    AppDbContext dbContext,
    IPasswordHasher<User> passwordHasher,
    JwtTokenService jwtTokenService)
{
    public async Task RegisterAsync(
        RegisterRequest request,
        CancellationToken cancellationToken = default)
    {
        var normalizedEmail = NormalizeAndValidateRegistrationEmail(request.Email);

        if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 8)
        {
            throw new ValidationException("Password must be at least 8 characters long.");
        }

        if (await dbContext.Users.AnyAsync(
                user => user.Email == normalizedEmail,
                cancellationToken))
        {
            throw new ConflictException("An account with this email already exists.");
        }

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = normalizedEmail,
            PasswordHash = string.Empty,
            CreatedAt = DateTime.UtcNow
        };

        user.PasswordHash = passwordHasher.HashPassword(user, request.Password);
        dbContext.Users.Add(user);

        try
        {
            await dbContext.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException exception)
            when (exception.InnerException is PostgresException
            {
                SqlState: PostgresErrorCodes.UniqueViolation
            })
        {
            throw new ConflictException("An account with this email already exists.");
        }
    }

    public async Task<AuthResponse> LoginAsync(
        LoginRequest request,
        CancellationToken cancellationToken = default)
    {
        var normalizedEmail = NormalizeEmail(request.Email);
        var user = string.IsNullOrEmpty(normalizedEmail)
            ? null
            : await dbContext.Users.SingleOrDefaultAsync(
                candidate => candidate.Email == normalizedEmail,
                cancellationToken);

        if (user is null ||
            passwordHasher.VerifyHashedPassword(user, user.PasswordHash, request.Password) ==
            PasswordVerificationResult.Failed)
        {
            throw new InvalidCredentialsException();
        }

        var accessToken = jwtTokenService.CreateAccessToken(user);
        return new AuthResponse(accessToken, user.Id, user.Email);
    }

    private static string NormalizeAndValidateRegistrationEmail(string email)
    {
        var normalizedEmail = NormalizeEmail(email);

        if (string.IsNullOrEmpty(normalizedEmail) ||
            !new EmailAddressAttribute().IsValid(normalizedEmail))
        {
            throw new ValidationException("A valid email address is required.");
        }

        return normalizedEmail;
    }

    private static string NormalizeEmail(string? email) =>
        email?.Trim().ToLowerInvariant() ?? string.Empty;
}
