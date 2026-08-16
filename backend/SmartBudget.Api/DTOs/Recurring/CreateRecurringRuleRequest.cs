using System.ComponentModel.DataAnnotations;
using SmartBudget.Api.Enums;

namespace SmartBudget.Api.DTOs.Recurring;

public sealed class CreateRecurringRuleRequest
{
    [EnumDataType(typeof(RecurringRecordType))]
    public RecurringRecordType RecordType { get; init; }

    public DateOnly StartDate { get; init; }

    public int? DurationMonths { get; init; }

    public DateOnly? EndDate { get; init; }

    [Range(
        typeof(decimal),
        "0.01",
        "79228162514264337593543950335",
        ParseLimitsInInvariantCulture = true)]
    public decimal? Amount { get; init; }

    public string? Description { get; init; }

    public Guid? CategoryId { get; init; }

    [EnumDataType(typeof(BillType))]
    public BillType? BillType { get; init; }
}
