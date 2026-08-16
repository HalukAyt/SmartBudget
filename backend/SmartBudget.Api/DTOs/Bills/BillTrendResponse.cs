using SmartBudget.Api.Enums;

namespace SmartBudget.Api.DTOs.Bills;

public sealed record BillTrendResponse(
    int Year,
    int Month,
    BillType BillType,
    decimal TotalAmount,
    decimal? TotalConsumption,
    string ConsumptionUnit);
