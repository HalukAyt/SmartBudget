using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SmartBudget.Api.Entities;

namespace SmartBudget.Api.Data.Configurations;

public sealed class BudgetConfiguration : IEntityTypeConfiguration<Budget>
{
    public void Configure(EntityTypeBuilder<Budget> builder)
    {
        builder.ToTable("Budgets");

        builder.HasKey(budget => budget.Id);
        builder.Property(budget => budget.Id).ValueGeneratedOnAdd();
        builder.Property(budget => budget.LimitAmount).HasPrecision(18, 2).IsRequired();
        builder.Property(budget => budget.Month).IsRequired();
        builder.Property(budget => budget.Year).IsRequired();
        builder.Property(budget => budget.CreatedAt)
            .HasColumnType("timestamp with time zone")
            .IsRequired();

        builder.HasIndex(budget => new
        {
            budget.UserId,
            budget.CategoryId,
            budget.Month,
            budget.Year
        })
            .IsUnique();

        builder.HasOne(budget => budget.User)
            .WithMany(user => user.Budgets)
            .HasForeignKey(budget => budget.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(budget => budget.Category)
            .WithMany(category => category.Budgets)
            .HasForeignKey(budget => budget.CategoryId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
