using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SmartBudget.Api.Entities;

namespace SmartBudget.Api.Data.Configurations;

public sealed class IncomeConfiguration : IEntityTypeConfiguration<Income>
{
    public void Configure(EntityTypeBuilder<Income> builder)
    {
        builder.ToTable("Incomes");

        builder.HasKey(income => income.Id);
        builder.Property(income => income.Id).ValueGeneratedOnAdd();
        builder.Property(income => income.Amount).HasPrecision(18, 2).IsRequired();
        builder.Property(income => income.Description).IsRequired(false);
        builder.Property(income => income.Date).HasColumnType("date").IsRequired();
        builder.Property(income => income.CreatedAt)
            .HasColumnType("timestamp with time zone")
            .IsRequired();

        builder.HasOne(income => income.User)
            .WithMany(user => user.Incomes)
            .HasForeignKey(income => income.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
