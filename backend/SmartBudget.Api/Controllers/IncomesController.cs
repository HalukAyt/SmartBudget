using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartBudget.Api.Authentication;
using SmartBudget.Api.DTOs.Incomes;
using SmartBudget.Api.Services;

namespace SmartBudget.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/incomes")]
public sealed class IncomesController(
    IncomeService incomeService,
    CurrentUserAccessor currentUserAccessor) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<IncomeListItemResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<IncomeListItemResponse>>> GetAll(
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var incomes = await incomeService.GetAllAsync(userId, cancellationToken);
        return Ok(incomes);
    }

    [HttpPost]
    [ProducesResponseType<IncomeResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IncomeResponse>> Create(
        CreateIncomeRequest request,
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var income = await incomeService.CreateAsync(userId, request, cancellationToken);
        return StatusCode(StatusCodes.Status201Created, income);
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(
        Guid id,
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        await incomeService.DeleteAsync(userId, id, cancellationToken);
        return NoContent();
    }
}
