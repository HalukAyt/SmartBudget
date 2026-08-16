namespace SmartBudget.Api.Entities;

public sealed class Expense
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public decimal Amount { get; set; }
    public required string Description { get; set; }
    public Guid CategoryId { get; set; }
    public DateOnly Date { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsAiCategorized { get; set; }
    public Guid? BillId { get; set; }

    public User User { get; set; } = null!;
    public Category Category { get; set; } = null!;
    public Bill? Bill { get; set; }
}
