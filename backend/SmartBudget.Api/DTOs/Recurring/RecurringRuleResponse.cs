using SmartBudget.Api.DTOs.Categories;
using SmartBudget.Api.Enums;

namespace SmartBudget.Api.DTOs.Recurring;

public sealed record RecurringRuleResponse(
    Guid Id,
    RecurringRecordType RecordType,
    RecurringFrequency Frequency,
    DateOnly StartDate,
    DateOnly EndDate,
    bool IsActive,
    decimal? Amount,
    string? Description,
    CategoryResponse? Category,
    BillType? BillType,
    bool IsRealizedThisMonth,
    DateOnly? NextDueDate,
    DateTime CreatedAt);
