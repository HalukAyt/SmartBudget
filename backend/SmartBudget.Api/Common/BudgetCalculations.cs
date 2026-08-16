using SmartBudget.Api.Enums;

namespace SmartBudget.Api.Common;

public static class BudgetCalculations
{
    public static decimal CalculateUsagePercent(
        decimal spentAmount,
        decimal limitAmount) =>
        spentAmount / limitAmount * 100;

    public static BudgetAlertStatus GetAlertStatus(decimal usagePercent) =>
        usagePercent switch
        {
            >= 100 => BudgetAlertStatus.Exceeded,
            >= 80 => BudgetAlertStatus.Warning,
            _ => BudgetAlertStatus.Normal
        };
}
