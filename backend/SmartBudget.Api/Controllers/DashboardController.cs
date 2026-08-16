using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartBudget.Api.Authentication;
using SmartBudget.Api.DTOs.Dashboard;
using SmartBudget.Api.Services;

namespace SmartBudget.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/dashboard")]
public sealed class DashboardController(
    DashboardService dashboardService,
    CurrentUserAccessor currentUserAccessor) : ControllerBase
{
    [HttpGet("monthly")]
    [ProducesResponseType<MonthlyDashboardResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<MonthlyDashboardResponse>> GetMonthly(
        [FromQuery] int? year,
        [FromQuery] int? month,
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var response = await dashboardService.GetMonthlyAsync(
            userId,
            year,
            month,
            cancellationToken);
        return Ok(response);
    }
}
