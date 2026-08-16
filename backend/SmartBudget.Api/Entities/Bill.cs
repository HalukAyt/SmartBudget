using SmartBudget.Api.Enums;

namespace SmartBudget.Api.Entities;

public sealed class Bill
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public BillType BillType { get; set; }
    public decimal Amount { get; set; }
    public decimal? ConsumptionValue { get; set; }
    public DateOnly BillingDate { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
    public Expense? Expense { get; set; }
}
