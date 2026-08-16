namespace SmartBudget.Api.Entities;

public sealed class User
{
    public Guid Id { get; set; }
    public required string Email { get; set; }
    public required string PasswordHash { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Expense> Expenses { get; set; } = new List<Expense>();
    public ICollection<Income> Incomes { get; set; } = new List<Income>();
    public ICollection<Budget> Budgets { get; set; } = new List<Budget>();
    public ICollection<Bill> Bills { get; set; } = new List<Bill>();
    public ICollection<RecurringFinancialRule> RecurringFinancialRules { get; set; } = new List<RecurringFinancialRule>();
    public ICollection<RecurringOccurrence> RecurringOccurrences { get; set; } = new List<RecurringOccurrence>();
}
