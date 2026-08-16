using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartBudget.Api.Authentication;
using SmartBudget.Api.DTOs.Bills;
using SmartBudget.Api.Services;

namespace SmartBudget.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/bills")]
public sealed class BillsController(
    BillService billService,
    CurrentUserAccessor currentUserAccessor) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<BillListItemResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<BillListItemResponse>>> GetAll(
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var bills = await billService.GetAllAsync(userId, cancellationToken);
        return Ok(bills);
    }

    [HttpGet("trends")]
    [ProducesResponseType<IReadOnlyList<BillTrendResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<BillTrendResponse>>> GetTrends(
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var trends = await billService.GetTrendsAsync(userId, cancellationToken);
        return Ok(trends);
    }

    [HttpPost]
    [ProducesResponseType<BillResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<BillResponse>> Create(
        CreateBillRequest request,
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var bill = await billService.CreateAsync(userId, request, cancellationToken);
        return StatusCode(StatusCodes.Status201Created, bill);
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
        await billService.DeleteAsync(userId, id, cancellationToken);
        return NoContent();
    }
}
