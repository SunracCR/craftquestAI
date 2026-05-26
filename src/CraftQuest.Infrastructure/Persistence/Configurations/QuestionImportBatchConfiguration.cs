using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class QuestionImportBatchConfiguration : IEntityTypeConfiguration<QuestionImportBatch>
{
    public void Configure(EntityTypeBuilder<QuestionImportBatch> builder)
    {
        builder.ToTable("QuestionImportBatches", "importing");
        builder.HasKey(x => x.QuestionImportBatchId);
        builder.Property(x => x.SourceType).HasMaxLength(40).IsRequired();
        builder.Property(x => x.OriginalFileName).HasMaxLength(260);
        builder.Property(x => x.Status).HasMaxLength(40).IsRequired();
        builder.Property(x => x.CqifVersion).HasMaxLength(20).IsRequired();

        builder.HasOne(x => x.Quiz)
            .WithMany()
            .HasForeignKey(x => x.QuizId);

        builder.HasMany(x => x.Rows)
            .WithOne(x => x.Batch)
            .HasForeignKey(x => x.QuestionImportBatchId);

        builder.HasMany(x => x.Errors)
            .WithOne(x => x.Batch)
            .HasForeignKey(x => x.QuestionImportBatchId);
    }
}
