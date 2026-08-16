using System.Text.Json.Serialization;

namespace SmartBudget.Api.Enums;

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum BillType
{
    Electricity = 1,
    Water = 2,
    NaturalGas = 3
}
