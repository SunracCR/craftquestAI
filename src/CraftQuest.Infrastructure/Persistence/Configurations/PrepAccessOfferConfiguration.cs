using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class PrepAccessOfferConfiguration : IEntityTypeConfiguration<PrepAccessOffer>
{
    public void Configure(EntityTypeBuilder<PrepAccessOffer> builder)
    {
        builder.ToTable("PrepAccessOffers", "catalog");
        builder.HasKey(x => x.OfferId);
        builder.Property(x => x.CurrencyCode).HasMaxLength(10).IsRequired();
        builder.Property(x => x.PriceAmount).HasPrecision(12, 2);
        builder.Property(x => x.StoreProductId).HasMaxLength(120);
        builder.HasIndex(x => new { x.CatalogItemId, x.DurationDays }).IsUnique();

        builder.HasOne(x => x.CatalogItem)
            .WithMany(x => x.AccessOffers)
            .HasForeignKey(x => x.CatalogItemId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
