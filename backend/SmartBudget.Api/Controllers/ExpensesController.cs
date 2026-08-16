using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartBudget.Api.Authentication;
using SmartBudget.Api.DTOs.Expenses;
using SmartBudget.Api.Services;

namespace SmartBudget.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/expenses")]
public sealed class ExpensesController(
    ExpenseService expenseService,
    CurrentUserAccessor currentUserAccessor) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<ExpenseListItemResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<ExpenseListItemResponse>>> GetAll(
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var expenses = await expenseService.GetAllAsync(userId, cancellationToken);
        return Ok(expenses);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType<ExpenseResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ExpenseResponse>> GetById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var expense = await expenseService.GetByIdAsync(userId, id, cancellationToken);
        return Ok(expense);
    }

    [HttpPost]
    [ProducesResponseType<ExpenseResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ExpenseResponse>> Create(
        CreateExpenseRequest request,
        CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetUserId();
        var expense = await expenseService.CreateAsync(userId, request, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = expense.Id }, expense);
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
        await expenseService.DeleteAsync(userId, id, cancellationToken);
        return NoContent();
    }
}
