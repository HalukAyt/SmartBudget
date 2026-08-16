using System.ComponentModel.DataAnnotations;
using SmartBudget.Api.Enums;

namespace SmartBudget.Api.DTOs.Bills;

public sealed class CreateBillRequest
{
    [EnumDataType(typeof(BillType))]
    public BillType BillType { get; init; }

    [Range(
        typeof(decimal),
        "0.01",
        "79228162514264337593543950335",
        ParseLimitsInInvariantCulture = true)]
    public decimal Amount { get; init; }

    [Range(
        typeof(decimal),
        "0.01",
        "79228162514264337593543950335",
        ParseLimitsInInvariantCulture = true)]
    public decimal? ConsumptionValue { get; init; }

    public DateOnly BillingDate { get; init; }
}
