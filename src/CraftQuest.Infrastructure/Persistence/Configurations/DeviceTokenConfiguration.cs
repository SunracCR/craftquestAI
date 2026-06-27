using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class DeviceTokenConfiguration : IEntityTypeConfiguration<DeviceToken>
{
    public void Configure(EntityTypeBuilder<DeviceToken> builder)
    {
        builder.ToTable("DeviceTokens", "core");
        builder.HasKey(x => x.DeviceTokenId);
        builder.Property(x => x.Token).HasMaxLength(512).IsRequired();
        builder.Property(x => x.Platform).HasMaxLength(20).IsRequired();

        builder.HasIndex(x => x.Token)
            .IsUnique()
            .HasDatabaseName("UQ_DeviceTokens_Token");

        builder.HasIndex(x => x.UserId)
            .HasDatabaseName("IX_DeviceTokens_UserId");

        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
