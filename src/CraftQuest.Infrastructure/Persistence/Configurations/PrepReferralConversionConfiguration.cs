using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class PrepReferralConversionConfiguration : IEntityTypeConfiguration<PrepReferralConversion>
{
    public void Configure(EntityTypeBuilder<PrepReferralConversion> builder)
    {
        builder.ToTable("PrepReferralConversions", "catalog");
        builder.HasKey(x => x.PrepReferralConversionId);
        builder.HasIndex(x => x.PurchaseId).IsUnique();
        builder.HasIndex(x => new { x.ReferrerUserId, x.BuyerUserId, x.CatalogItemId }).IsUnique();

        builder.HasOne(x => x.ReferralCode)
            .WithMany()
            .HasForeignKey(x => x.ReferralCodeId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.ReferrerUser)
            .WithMany()
            .HasForeignKey(x => x.ReferrerUserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.BuyerUser)
            .WithMany()
            .HasForeignKey(x => x.BuyerUserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.CatalogItem)
            .WithMany()
            .HasForeignKey(x => x.CatalogItemId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Purchase)
            .WithMany()
            .HasForeignKey(x => x.PurchaseId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
