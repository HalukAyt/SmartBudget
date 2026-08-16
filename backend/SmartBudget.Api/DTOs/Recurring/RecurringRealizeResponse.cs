using SmartBudget.Api.Enums;

namespace SmartBudget.Api.DTOs.Recurring;

public sealed record RecurringRealizeResponse(
    RecurringRecordType RecordType,
    Guid RuleId,
    Guid CreatedRecordId,
    int Year,
    int Month);
