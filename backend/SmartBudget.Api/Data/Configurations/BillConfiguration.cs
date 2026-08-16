using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SmartBudget.Api.Entities;

namespace SmartBudget.Api.Data.Configurations;

public sealed class BillConfiguration : IEntityTypeConfiguration<Bill>
{
    public void Configure(EntityTypeBuilder<Bill> builder)
    {
        builder.ToTable("Bills", tableBuilder =>
            tableBuilder.HasCheckConstraint(
                "CK_Bills_BillType",
                "\"BillType\" IN (1, 2, 3)"));

        builder.HasKey(bill => bill.Id);
        builder.Property(bill => bill.Id).ValueGeneratedOnAdd();
        builder.Property(bill => bill.BillType).HasConversion<int>().IsRequired();
        builder.Property(bill => bill.Amount).HasPrecision(18, 2).IsRequired();
        builder.Property(bill => bill.ConsumptionValue).IsRequired(false);
        builder.Property(bill => bill.BillingDate).HasColumnType("date").IsRequired();
        builder.Property(bill => bill.CreatedAt)
            .HasColumnType("timestamp with time zone")
            .IsRequired();

        builder.HasOne(bill => bill.User)
            .WithMany(user => user.Bills)
            .HasForeignKey(bill => bill.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
