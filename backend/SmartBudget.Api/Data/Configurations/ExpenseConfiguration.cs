using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SmartBudget.Api.Entities;

namespace SmartBudget.Api.Data.Configurations;

public sealed class ExpenseConfiguration : IEntityTypeConfiguration<Expense>
{
    public void Configure(EntityTypeBuilder<Expense> builder)
    {
        builder.ToTable("Expenses");

        builder.HasKey(expense => expense.Id);
        builder.Property(expense => expense.Id).ValueGeneratedOnAdd();
        builder.Property(expense => expense.Amount).HasPrecision(18, 2).IsRequired();
        builder.Property(expense => expense.Description).IsRequired();
        builder.Property(expense => expense.Date).HasColumnType("date").IsRequired();
        builder.Property(expense => expense.CreatedAt)
            .HasColumnType("timestamp with time zone")
            .IsRequired();
        builder.Property(expense => expense.IsAiCategorized).IsRequired();
        builder.Property(expense => expense.BillId).IsRequired(false);
        builder.HasIndex(expense => expense.BillId).IsUnique();

        builder.HasOne(expense => expense.User)
            .WithMany(user => user.Expenses)
            .HasForeignKey(expense => expense.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(expense => expense.Category)
            .WithMany(category => category.Expenses)
            .HasForeignKey(expense => expense.CategoryId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(expense => expense.Bill)
            .WithOne(bill => bill.Expense)
            .HasForeignKey<Expense>(expense => expense.BillId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
