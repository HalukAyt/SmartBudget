using Microsoft.EntityFrameworkCore;
using SmartBudget.Api.Entities;

namespace SmartBudget.Api.Data;

public sealed class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Expense> Expenses => Set<Expense>();
    public DbSet<Income> Incomes => Set<Income>();
    public DbSet<Budget> Budgets => Set<Budget>();
    public DbSet<Bill> Bills => Set<Bill>();
    public DbSet<RecurringFinancialRule> RecurringFinancialRules => Set<RecurringFinancialRule>();
    public DbSet<RecurringOccurrence> RecurringOccurrences => Set<RecurringOccurrence>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }
}
