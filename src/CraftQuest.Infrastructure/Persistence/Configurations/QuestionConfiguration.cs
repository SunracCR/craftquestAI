using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class QuestionConfiguration : IEntityTypeConfiguration<Question>
{
    public void Configure(EntityTypeBuilder<Question> builder)
    {
        builder.ToTable("Questions", "quiz");
        builder.HasKey(x => x.QuestionId);
        builder.Property(x => x.QuestionText).IsRequired();
        builder.Property(x => x.Points).HasPrecision(10, 2);
        builder.Property(x => x.Difficulty).HasMaxLength(30);
        builder.Property(x => x.ExplanationVisibility).HasMaxLength(40).IsRequired();
        builder.Property(x => x.ScoringPolicy).HasMaxLength(40).IsRequired();
        builder.Property(x => x.ReviewStatus).HasMaxLength(40).IsRequired();

        builder.HasOne(x => x.QuestionType)
            .WithMany(x => x.Questions)
            .HasForeignKey(x => x.QuestionTypeId);

        builder.HasMany(x => x.AnswerOptions)
            .WithOne(x => x.Question)
            .HasForeignKey(x => x.QuestionId);

        builder.HasMany(x => x.CorrectAnswerOptions)
            .WithOne(x => x.Question)
            .HasForeignKey(x => x.QuestionId);

        builder.HasOne(x => x.Justification)
            .WithOne(x => x.Question)
            .HasForeignKey<QuestionJustification>(x => x.QuestionId);

        builder.HasQueryFilter(x => x.DeletedAt == null);

        builder.HasIndex(x => new { x.QuizId, x.SortOrder })
            .HasFilter("[DeletedAt] IS NULL")
            .HasDatabaseName("IX_Questions_Quiz");
    }
}
