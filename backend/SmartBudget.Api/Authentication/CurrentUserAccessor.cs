using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace SmartBudget.Api.Authentication;

public sealed class CurrentUserAccessor(IHttpContextAccessor httpContextAccessor)
{
    public Guid GetUserId()
    {
        var principal = httpContextAccessor.HttpContext?.User;
        var claimValue = principal?.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? principal?.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

        if (!Guid.TryParse(claimValue, out var userId))
        {
            throw new UnauthorizedAccessException("Authenticated user id claim is missing or invalid.");
        }

        return userId;
    }
}
