using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class PrepCatalogItemConfiguration : IEntityTypeConfiguration<PrepCatalogItem>
{
    public void Configure(EntityTypeBuilder<PrepCatalogItem> builder)
    {
        builder.ToTable("PrepCatalogItems", "catalog");
        builder.HasKey(x => x.CatalogItemId);
        builder.Property(x => x.TitleOverride).HasMaxLength(220);
        builder.Property(x => x.Description).HasMaxLength(2000);
        builder.Property(x => x.InstitutionTag).HasMaxLength(120);
        builder.HasIndex(x => x.QuizId).IsUnique();

        builder.HasOne(x => x.Quiz)
            .WithMany()
            .HasForeignKey(x => x.QuizId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Category)
            .WithMany(x => x.CatalogItems)
            .HasForeignKey(x => x.CategoryId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.CoverMedia)
            .WithMany()
            .HasForeignKey(x => x.CoverMediaId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(x => x.CreatedByUser)
            .WithMany()
            .HasForeignKey(x => x.CreatedByUserId);
    }
}
