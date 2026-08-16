using SmartBudget.Api.Enums;

namespace SmartBudget.Api.DTOs.Bills;

public sealed record BillListItemResponse(
    Guid Id,
    BillType BillType,
    decimal Amount,
    decimal? ConsumptionValue,
    string ConsumptionUnit,
    DateOnly BillingDate,
    DateTime CreatedAt);
