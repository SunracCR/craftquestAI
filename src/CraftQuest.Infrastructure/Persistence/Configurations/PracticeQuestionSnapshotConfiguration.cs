using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class PracticeQuestionSnapshotConfiguration : IEntityTypeConfiguration<PracticeQuestionSnapshot>
{
    public void Configure(EntityTypeBuilder<PracticeQuestionSnapshot> builder)
    {
        builder.ToTable("PracticeQuestionSnapshots", "practice");
        builder.HasKey(x => x.PracticeQuestionSnapshotId);
        builder.Property(x => x.QuestionTypeCodeSnapshot).HasMaxLength(60).IsRequired();
        builder.Property(x => x.QuizSectionNameSnapshot).HasMaxLength(160);
        builder.Property(x => x.PointsPossible).HasPrecision(10, 2);
        builder.Property(x => x.PointsAwarded).HasPrecision(10, 2);
        builder.Property(x => x.AnswerStatus).HasMaxLength(40).IsRequired();
        builder.Property(x => x.RandomizationSeed).HasMaxLength(100);

        builder.HasMany(x => x.AnswerOptionSnapshots)
            .WithOne(x => x.PracticeQuestionSnapshot)
            .HasForeignKey(x => x.PracticeQuestionSnapshotId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
