using SmartBudget.Api.Enums;

namespace SmartBudget.Api.DTOs.Bills;

public sealed record BillResponse(
    Guid Id,
    BillType BillType,
    decimal Amount,
    decimal? ConsumptionValue,
    string ConsumptionUnit,
    DateOnly BillingDate,
    DateTime CreatedAt);
