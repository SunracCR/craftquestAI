using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class PrepCategoryConfiguration : IEntityTypeConfiguration<PrepCategory>
{
    public void Configure(EntityTypeBuilder<PrepCategory> builder)
    {
        builder.ToTable("PrepCategories", "catalog");
        builder.HasKey(x => x.CategoryId);
        builder.Property(x => x.CategoryType).HasMaxLength(20).IsRequired();
        builder.Property(x => x.Slug).HasMaxLength(80).IsRequired();
        builder.Property(x => x.Name).HasMaxLength(120).IsRequired();
        builder.Property(x => x.Description).HasMaxLength(500);
        builder.Property(x => x.CountryCode).HasMaxLength(10);
        builder.Property(x => x.IconKey).HasMaxLength(60);

        builder.HasIndex(x => new { x.ParentCategoryId, x.Slug }).IsUnique();

        builder.HasOne(x => x.Parent)
            .WithMany(x => x.Children)
            .HasForeignKey(x => x.ParentCategoryId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
