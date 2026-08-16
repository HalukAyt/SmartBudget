using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartBudget.Api.Authentication;
using SmartBudget.Api.DTOs.Budgets;
using SmartBudget.Api.Services;

namespace SmartBudget.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/budgets")]
public sealed class BudgetsController(
    BudgetService budgetService,
    CurrentUserAccessor currentUserAccessor) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<BudgetListItemResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<BudgetListItemResponse>>> GetAll(
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var budgets = await budgetService.GetAllAsync(userId, cancellationToken);
        return Ok(budgets);
    }

    [HttpPost]
    [ProducesResponseType<BudgetResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<BudgetResponse>> Create(
        CreateBudgetRequest request,
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var budget = await budgetService.CreateAsync(userId, request, cancellationToken);
        return StatusCode(StatusCodes.Status201Created, budget);
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType<BudgetResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<BudgetResponse>> Update(
        Guid id,
        UpdateBudgetRequest request,
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var budget = await budgetService.UpdateAsync(
            userId,
            id,
            request,
            cancellationToken);
        return Ok(budget);
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
        await budgetService.DeleteAsync(userId, id, cancellationToken);
        return NoContent();
    }
}
