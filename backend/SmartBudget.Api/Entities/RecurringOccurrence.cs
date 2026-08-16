using SmartBudget.Api.Enums;

namespace SmartBudget.Api.Entities;

public sealed class RecurringOccurrence
{
    public Guid Id { get; set; }
    public Guid RecurringRuleId { get; set; }
    public Guid UserId { get; set; }
    public int Year { get; set; }
    public int Month { get; set; }
    public RecurringRecordType RecordType { get; set; }
    public Guid? CreatedRecordId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public RecurringFinancialRule RecurringRule { get; set; } = null!;
    public User User { get; set; } = null!;
}
