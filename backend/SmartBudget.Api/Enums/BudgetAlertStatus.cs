using System.Text.Json.Serialization;

namespace SmartBudget.Api.Enums;

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum BudgetAlertStatus
{
    Normal,
    Warning,
    Exceeded
}
