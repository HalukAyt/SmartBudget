using SmartBudget.Api.Enums;

namespace SmartBudget.Api.Entities;

public sealed class RecurringFinancialRule
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public RecurringRecordType RecordType { get; set; }
    public RecurringFrequency Frequency { get; set; } = RecurringFrequency.Monthly;
    public DateOnly StartDate { get; set; }
    public DateOnly EndDate { get; set; }
    public bool IsActive { get; set; } = true;
    public decimal? Amount { get; set; }
    public string? Description { get; set; }
    public Guid? CategoryId { get; set; }
    public BillType? BillType { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
    public Category? Category { get; set; }
    public ICollection<RecurringOccurrence> Occurrences { get; set; } = new List<RecurringOccurrence>();
}
