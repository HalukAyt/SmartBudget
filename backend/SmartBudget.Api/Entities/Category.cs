namespace SmartBudget.Api.Entities;

public sealed class Category
{
    public Guid Id { get; set; }
    public required string Name { get; set; }

    public ICollection<Expense> Expenses { get; set; } = new List<Expense>();
    public ICollection<Budget> Budgets { get; set; } = new List<Budget>();
}
