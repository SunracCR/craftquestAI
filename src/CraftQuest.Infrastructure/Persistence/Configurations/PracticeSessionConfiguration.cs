using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class PracticeSessionConfiguration : IEntityTypeConfiguration<PracticeSession>
{
    public void Configure(EntityTypeBuilder<PracticeSession> builder)
    {
        builder.ToTable("PracticeSessions", "practice");
        builder.HasKey(x => x.PracticeSessionId);
        builder.Property(x => x.Status).HasMaxLength(40).IsRequired();
        builder.Property(x => x.RandomizationStrategy).HasMaxLength(40).IsRequired();
        builder.Property(x => x.ScoreObtained).HasPrecision(10, 2);
        builder.Property(x => x.ScorePossible).HasPrecision(10, 2);

        builder.HasOne(x => x.StudentUser)
            .WithMany()
            .HasForeignKey(x => x.StudentUserId)
            .IsRequired(false)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Quiz)
            .WithMany()
            .HasForeignKey(x => x.QuizId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(x => x.QuestionSnapshots)
            .WithOne(x => x.PracticeSession)
            .HasForeignKey(x => x.PracticeSessionId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
