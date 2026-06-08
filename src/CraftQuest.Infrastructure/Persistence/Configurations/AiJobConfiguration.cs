using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class AiJobConfiguration : IEntityTypeConfiguration<AiJob>
{
    public void Configure(EntityTypeBuilder<AiJob> builder)
    {
        builder.ToTable("AiJobs", "ai");
        builder.HasKey(x => x.AiJobId);
        builder.Property(x => x.JobType).HasMaxLength(80).IsRequired();
        builder.Property(x => x.Status).HasMaxLength(40).IsRequired();
        builder.Property(x => x.ModelName).HasMaxLength(120);
        builder.Property(x => x.PromptVersion).HasMaxLength(80);
        builder.Property(x => x.ErrorMessage).HasMaxLength(2000);
        builder.Property(x => x.ErrorCode).HasMaxLength(80);
        builder.Property(x => x.Stage).HasMaxLength(40);
        builder.Property(x => x.RetryAttempt).HasDefaultValue(0);
        builder.Property(x => x.InputJson);
        builder.Property(x => x.ResultJson);
        builder.Property(x => x.EstimatedCostUsd).HasPrecision(12, 6);

        builder.HasOne(x => x.RequestedByUser)
            .WithMany()
            .HasForeignKey(x => x.RequestedByUserId);

        builder.HasOne<StudyMaterial>()
            .WithMany()
            .HasForeignKey(x => x.StudyMaterialId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(x => new { x.RequestedByUserId, x.JobType, x.Status, x.TargetQuizId })
            .HasFilter("[TargetQuizId] IS NOT NULL")
            .IncludeProperties(x => new { x.CompletedAt, x.QuestionImportBatchId })
            .HasDatabaseName("IX_AiJobs_PendingImportByQuiz");
    }
}
