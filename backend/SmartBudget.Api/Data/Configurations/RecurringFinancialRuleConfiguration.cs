using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SmartBudget.Api.Entities;

namespace SmartBudget.Api.Data.Configurations;

public sealed class RecurringFinancialRuleConfiguration : IEntityTypeConfiguration<RecurringFinancialRule>
{
    public void Configure(EntityTypeBuilder<RecurringFinancialRule> builder)
    {
        builder.ToTable("RecurringFinancialRules", tableBuilder =>
        {
            tableBuilder.HasCheckConstraint(
                "CK_RecurringFinancialRules_RecordType",
                "\"RecordType\" IN (1, 2, 3)");
            tableBuilder.HasCheckConstraint(
                "CK_RecurringFinancialRules_Frequency",
                "\"Frequency\" IN (1)");
            tableBuilder.HasCheckConstraint(
                "CK_RecurringFinancialRules_BillType",
                "\"BillType\" IS NULL OR \"BillType\" IN (1, 2, 3)");
        });

        builder.HasKey(rule => rule.Id);
        builder.Property(rule => rule.Id).ValueGeneratedOnAdd();
        builder.Property(rule => rule.RecordType).HasConversion<int>().IsRequired();
        builder.Property(rule => rule.Frequency).HasConversion<int>().IsRequired();
        builder.Property(rule => rule.StartDate).HasColumnType("date").IsRequired();
        builder.Property(rule => rule.EndDate).HasColumnType("date").IsRequired();
        builder.Property(rule => rule.IsActive).IsRequired();
        builder.Property(rule => rule.Amount).HasPrecision(18, 2).IsRequired(false);
        builder.Property(rule => rule.Description).IsRequired(false);
        builder.Property(rule => rule.BillType).HasConversion<int?>().IsRequired(false);
        builder.Property(rule => rule.CreatedAt)
            .HasColumnType("timestamp with time zone")
            .IsRequired();

        builder.HasOne(rule => rule.User)
            .WithMany(user => user.RecurringFinancialRules)
            .HasForeignKey(rule => rule.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(rule => rule.Category)
            .WithMany()
            .HasForeignKey(rule => rule.CategoryId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
