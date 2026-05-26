using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class StudyMaterialConfiguration : IEntityTypeConfiguration<StudyMaterial>
{
    public void Configure(EntityTypeBuilder<StudyMaterial> builder)
    {
        builder.ToTable("StudyMaterials", "content");
        builder.HasKey(x => x.StudyMaterialId);
        builder.Property(x => x.FileType).HasMaxLength(50).IsRequired();
        builder.Property(x => x.ProcessingStatus).HasMaxLength(30).IsRequired();
        builder.Property(x => x.Title).HasMaxLength(260);
        builder.Property(x => x.OriginalFileName).HasMaxLength(260);
        builder.Property(x => x.LanguageCode).HasMaxLength(10);
        builder.Property(x => x.ErrorMessage).HasMaxLength(2000);
        builder.Property(x => x.BlobPath).HasMaxLength(1000);
        builder.Property(x => x.SelectionTopic).HasMaxLength(500);
        builder.Property(x => x.EditedExtractedText);

        builder.HasOne(x => x.UploadedByUser)
            .WithMany()
            .HasForeignKey(x => x.UploadedByUserId);

        builder.HasOne(x => x.MediaAsset)
            .WithMany()
            .HasForeignKey(x => x.MediaAssetId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(x => x.GeneratedQuiz)
            .WithMany()
            .HasForeignKey(x => x.GeneratedQuizId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}

public class StudyMaterialPageConfiguration : IEntityTypeConfiguration<StudyMaterialPage>
{
    public void Configure(EntityTypeBuilder<StudyMaterialPage> builder)
    {
        builder.ToTable("StudyMaterialPages", "content");
        builder.HasKey(x => x.StudyMaterialPageId);
        builder.Property(x => x.ExtractionQuality).HasMaxLength(20).IsRequired();
        builder.Property(x => x.ImageBlobPath).HasMaxLength(1000);
        builder.HasIndex(x => new { x.StudyMaterialId, x.PageNumber }).IsUnique();

        builder.HasOne(x => x.StudyMaterial)
            .WithMany(m => m.Pages)
            .HasForeignKey(x => x.StudyMaterialId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class StudyMaterialSectionConfiguration : IEntityTypeConfiguration<StudyMaterialSection>
{
    public void Configure(EntityTypeBuilder<StudyMaterialSection> builder)
    {
        builder.ToTable("StudyMaterialSections", "content");
        builder.HasKey(x => x.StudyMaterialSectionId);
        builder.Property(x => x.Title).HasMaxLength(300).IsRequired();

        builder.HasOne(x => x.StudyMaterial)
            .WithMany(m => m.Sections)
            .HasForeignKey(x => x.StudyMaterialId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
