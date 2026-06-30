using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class ParentalConsentTokenConfiguration : IEntityTypeConfiguration<ParentalConsentToken>
{
    public void Configure(EntityTypeBuilder<ParentalConsentToken> builder)
    {
        builder.ToTable("ParentalConsentTokens", "core");
        builder.HasKey(x => x.ParentalConsentTokenId);
        builder.Property(x => x.TokenHash).HasMaxLength(128).IsRequired();
        builder.HasIndex(x => x.TokenHash);
        builder.HasIndex(x => new { x.UserId, x.UsedAt });

        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
