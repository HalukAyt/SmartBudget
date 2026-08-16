using System.ComponentModel.DataAnnotations;
using System.Globalization;
using SmartBudget.Api.DTOs.Bills;
using SmartBudget.Api.DTOs.Budgets;
using SmartBudget.Api.DTOs.Expenses;
using SmartBudget.Api.DTOs.Incomes;
using SmartBudget.Api.Enums;

namespace SmartBudget.Api.Tests.Validation;

public sealed class DecimalRangeCultureTests
{
    [Fact]
    public void Decimal_ranges_use_invariant_limits_under_turkish_culture()
    {
        var originalCulture = CultureInfo.CurrentCulture;
        var originalUiCulture = CultureInfo.CurrentUICulture;

        try
        {
            CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo("tr-TR");
            CultureInfo.CurrentUICulture = CultureInfo.GetCultureInfo("tr-TR");

            AssertValid(new CreateIncomeRequest
            {
                Amount = 10.50m,
                Date = new DateOnly(2026, 8, 16)
            });
            AssertValid(new CreateExpenseRequest
            {
                Amount = 10.50m,
                Description = "Test",
                CategoryId = Guid.NewGuid(),
                Date = new DateOnly(2026, 8, 16)
            });
            AssertValid(new CreateBudgetRequest
            {
                CategoryId = Guid.NewGuid(),
                LimitAmount = 10.50m,
                Month = 8,
                Year = 2026
            });
            AssertValid(new UpdateBudgetRequest { LimitAmount = 10.50m });
            AssertValid(new CreateBillRequest
            {
                BillType = BillType.Electricity,
                Amount = 10.50m,
                ConsumptionValue = 1.25m,
                BillingDate = new DateOnly(2026, 8, 16)
            });

            AssertInvalid(new CreateIncomeRequest
            {
                Amount = 0,
                Date = new DateOnly(2026, 8, 16)
            });
        }
        finally
        {
            CultureInfo.CurrentCulture = originalCulture;
            CultureInfo.CurrentUICulture = originalUiCulture;
        }
    }

    private static void AssertValid(object value)
    {
        var results = new List<ValidationResult>();
        Assert.True(Validator.TryValidateObject(
            value,
            new ValidationContext(value),
            results,
            validateAllProperties: true),
            string.Join(Environment.NewLine, results.Select(result => result.ErrorMessage)));
    }

    private static void AssertInvalid(object value)
    {
        var results = new List<ValidationResult>();
        Assert.False(Validator.TryValidateObject(
            value,
            new ValidationContext(value),
            results,
            validateAllProperties: true));
    }
}
