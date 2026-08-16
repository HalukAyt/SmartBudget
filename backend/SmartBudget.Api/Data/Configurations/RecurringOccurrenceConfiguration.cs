using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SmartBudget.Api.Entities;

namespace SmartBudget.Api.Data.Configurations;

public sealed class RecurringOccurrenceConfiguration : IEntityTypeConfiguration<RecurringOccurrence>
{
    public void Configure(EntityTypeBuilder<RecurringOccurrence> builder)
    {
        builder.ToTable("RecurringOccurrences", tableBuilder =>
            tableBuilder.HasCheckConstraint(
                "CK_RecurringOccurrences_RecordType",
                "\"RecordType\" IN (1, 2, 3)"));

        builder.HasKey(occurrence => occurrence.Id);
        builder.Property(occurrence => occurrence.Id).ValueGeneratedOnAdd();
        builder.Property(occurrence => occurrence.RecordType).HasConversion<int>().IsRequired();
        builder.Property(occurrence => occurrence.Year).IsRequired();
        builder.Property(occurrence => occurrence.Month).IsRequired();
        builder.Property(occurrence => occurrence.CreatedRecordId).IsRequired(false);
        builder.Property(occurrence => occurrence.CreatedAt)
            .HasColumnType("timestamp with time zone")
            .IsRequired();

        builder.HasIndex(occurrence => new
        {
            occurrence.RecurringRuleId,
            occurrence.Year,
            occurrence.Month
        }).IsUnique();

        builder.HasOne(occurrence => occurrence.RecurringRule)
            .WithMany(rule => rule.Occurrences)
            .HasForeignKey(occurrence => occurrence.RecurringRuleId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(occurrence => occurrence.User)
            .WithMany(user => user.RecurringOccurrences)
            .HasForeignKey(occurrence => occurrence.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
