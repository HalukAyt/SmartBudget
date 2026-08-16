using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using SmartBudget.Api.Authentication;

namespace SmartBudget.Api.Tests.Authentication;

public sealed class CurrentUserAccessorTests
{
    [Fact]
    public void GetUserId_reads_and_parses_authenticated_user_id_claim()
    {
        var expectedUserId = Guid.NewGuid();
        var context = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity(
                new[]
                {
                    new Claim(JwtRegisteredClaimNames.Sub, expectedUserId.ToString())
                },
                "Test"))
        };
        var accessor = new CurrentUserAccessor(new HttpContextAccessor
        {
            HttpContext = context
        });

        var userId = accessor.GetUserId();

        Assert.Equal(expectedUserId, userId);
    }

    [Fact]
    public void GetUserId_with_invalid_claim_throws_unauthorized_error()
    {
        var context = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity(
                new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, "not-a-guid")
                },
                "Test"))
        };
        var accessor = new CurrentUserAccessor(new HttpContextAccessor
        {
            HttpContext = context
        });

        Assert.Throws<UnauthorizedAccessException>(() => accessor.GetUserId());
    }
}
