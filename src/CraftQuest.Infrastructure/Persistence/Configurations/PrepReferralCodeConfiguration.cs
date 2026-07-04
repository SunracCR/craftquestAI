using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class PrepReferralCodeConfiguration : IEntityTypeConfiguration<PrepReferralCode>
{
    public void Configure(EntityTypeBuilder<PrepReferralCode> builder)
    {
        builder.ToTable("PrepReferralCodes", "catalog");
        builder.HasKey(x => x.ReferralCodeId);
        builder.Property(x => x.Code).HasMaxLength(20).IsRequired();
        builder.HasIndex(x => x.Code).IsUnique();
        builder.HasIndex(x => new { x.ReferrerUserId, x.CatalogItemId }).IsUnique();

        builder.HasOne(x => x.CatalogItem)
            .WithMany()
            .HasForeignKey(x => x.CatalogItemId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.ReferrerUser)
            .WithMany()
            .HasForeignKey(x => x.ReferrerUserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
