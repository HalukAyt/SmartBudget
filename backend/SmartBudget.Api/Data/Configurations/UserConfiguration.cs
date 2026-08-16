using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SmartBudget.Api.Entities;

namespace SmartBudget.Api.Data.Configurations;

public sealed class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("Users");

        builder.HasKey(user => user.Id);
        builder.Property(user => user.Id).ValueGeneratedOnAdd();

        builder.Property(user => user.Email).IsRequired();
        builder.HasIndex(user => user.Email).IsUnique();

        builder.Property(user => user.PasswordHash).IsRequired();
        builder.Property(user => user.CreatedAt)
            .HasColumnType("timestamp with time zone")
            .IsRequired();
    }
}
