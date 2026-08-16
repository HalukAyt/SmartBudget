using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartBudget.Api.Authentication;
using SmartBudget.Api.DTOs.AI;
using SmartBudget.Api.Services.AI;

namespace SmartBudget.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/ai")]
public sealed class AiController(
    AiCategorizationService categorizationService,
    AiMonthlyAnalysisService monthlyAnalysisService,
    CurrentUserAccessor currentUserAccessor) : ControllerBase
{
    [HttpPost("categorize-expense")]
    [ProducesResponseType<CategorizeExpenseResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<CategorizeExpenseResponse>> CategorizeExpense(
        CategorizeExpenseRequest request,
        CancellationToken cancellationToken)
    {
        _ = currentUserAccessor.GetUserId();
        var response = await categorizationService.CategorizeAsync(
            request,
            cancellationToken);
        return Ok(response);
    }

    [HttpPost("monthly-summary")]
    [ProducesResponseType<MonthlyAnalysisResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<MonthlyAnalysisResponse>> MonthlySummary(
        MonthlyAnalysisRequest request,
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var response = await monthlyAnalysisService.AnalyzeAsync(
            userId,
            request,
            cancellationToken);
        return Ok(response);
    }
}
