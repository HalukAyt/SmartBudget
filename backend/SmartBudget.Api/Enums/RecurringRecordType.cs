using System.Text.Json.Serialization;

namespace SmartBudget.Api.Enums;

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum RecurringRecordType
{
    Income = 1,
    Expense = 2,
    Bill = 3
}
