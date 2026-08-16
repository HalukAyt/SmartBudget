using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartBudget.Api.Authentication;
using SmartBudget.Api.DTOs.Recurring;
using SmartBudget.Api.Services;

namespace SmartBudget.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/recurring-rules")]
public sealed class RecurringRulesController(
    RecurringRuleService recurringRuleService,
    CurrentUserAccessor currentUserAccessor) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<RecurringRuleResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<RecurringRuleResponse>>> GetAll(
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var rules = await recurringRuleService.GetAllAsync(userId, cancellationToken);
        return Ok(rules);
    }

    [HttpGet("due")]
    [ProducesResponseType<IReadOnlyList<RecurringRuleResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<RecurringRuleResponse>>> GetDue(
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var rules = await recurringRuleService.GetDueAsync(userId, cancellationToken);
        return Ok(rules);
    }

    [HttpPost]
    [ProducesResponseType<RecurringRuleResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<RecurringRuleResponse>> Create(
        CreateRecurringRuleRequest request,
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var rule = await recurringRuleService.CreateAsync(userId, request, cancellationToken);
        return StatusCode(StatusCodes.Status201Created, rule);
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType<RecurringRuleResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<RecurringRuleResponse>> Update(
        Guid id,
        UpdateRecurringRuleRequest request,
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var rule = await recurringRuleService.UpdateAsync(userId, id, request, cancellationToken);
        return Ok(rule);
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
        await recurringRuleService.DeleteAsync(userId, id, cancellationToken);
        return NoContent();
    }

    [HttpPost("{id:guid}/realize")]
    [ProducesResponseType<RecurringRealizeResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<RecurringRealizeResponse>> Realize(
        Guid id,
        RealizeRecurringRuleRequest request,
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var result = await recurringRuleService.RealizeAsync(
            userId,
            id,
            request,
            cancellationToken);
        return StatusCode(StatusCodes.Status201Created, result);
    }
}
