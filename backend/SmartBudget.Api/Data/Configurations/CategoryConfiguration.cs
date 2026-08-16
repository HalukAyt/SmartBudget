using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SmartBudget.Api.Entities;

namespace SmartBudget.Api.Data.Configurations;

public sealed class CategoryConfiguration : IEntityTypeConfiguration<Category>
{
    public void Configure(EntityTypeBuilder<Category> builder)
    {
        builder.ToTable("Categories");

        builder.HasKey(category => category.Id);
        builder.Property(category => category.Id).ValueGeneratedOnAdd();
        builder.Property(category => category.Name).IsRequired();

        builder.HasData(
            new Category { Id = Guid.Parse("00000000-0000-0000-0000-000000000001"), Name = "Market" },
            new Category { Id = Guid.Parse("00000000-0000-0000-0000-000000000002"), Name = "Ulaşım" },
            new Category { Id = SeedCategoryIds.Bill, Name = "Fatura" },
            new Category { Id = Guid.Parse("00000000-0000-0000-0000-000000000004"), Name = "Eğlence" },
            new Category { Id = Guid.Parse("00000000-0000-0000-0000-000000000005"), Name = "Sağlık" },
            new Category { Id = Guid.Parse("00000000-0000-0000-0000-000000000006"), Name = "Eğitim" },
            new Category { Id = Guid.Parse("00000000-0000-0000-0000-000000000007"), Name = "Kira" },
            new Category { Id = Guid.Parse("00000000-0000-0000-0000-000000000008"), Name = "Diğer" });
    }
}
