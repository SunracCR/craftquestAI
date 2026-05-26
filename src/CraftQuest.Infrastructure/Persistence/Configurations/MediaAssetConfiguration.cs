using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class MediaAssetConfiguration : IEntityTypeConfiguration<MediaAsset>
{
    public void Configure(EntityTypeBuilder<MediaAsset> builder)
    {
        builder.ToTable("MediaAssets", "content");
        builder.HasKey(x => x.MediaAssetId);
        builder.Property(x => x.StorageProvider).HasMaxLength(40).IsRequired();
        builder.Property(x => x.ContainerName).HasMaxLength(120).IsRequired();
        builder.Property(x => x.BlobPath).HasMaxLength(1000).IsRequired();
        builder.Property(x => x.OriginalFileName).HasMaxLength(260).IsRequired();
        builder.Property(x => x.ContentType).HasMaxLength(120);
        builder.Property(x => x.FileExtension).HasMaxLength(20);
        builder.Property(x => x.Sha256Hash).HasMaxLength(128);
        builder.Property(x => x.AltText).HasMaxLength(500);
        builder.Property(x => x.Status).HasMaxLength(30).IsRequired();

        builder.HasOne(x => x.UploadedByUser)
            .WithMany()
            .HasForeignKey(x => x.UploadedByUserId);
    }
}
