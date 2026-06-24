using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class QuizConfiguration : IEntityTypeConfiguration<Quiz>
{
    public void Configure(EntityTypeBuilder<Quiz> builder)
    {
        builder.ToTable("Quizzes", "quiz");
        builder.HasKey(x => x.QuizId);
        builder.Property(x => x.Title).HasMaxLength(220).IsRequired();
        builder.Property(x => x.Description).HasMaxLength(1000);
        builder.Property(x => x.Visibility).HasMaxLength(40).IsRequired();
        builder.Property(x => x.PublicationStatus).HasMaxLength(40).IsRequired();
        builder.Property(x => x.DefaultQuestionPoints).HasPrecision(10, 2);
        builder.Property(x => x.TargetCountryCode).HasMaxLength(10);

        builder.HasIndex(x => x.FolderId)
            .HasFilter("[DeletedAt] IS NULL")
            .HasDatabaseName("IX_Quizzes_Folder");

        builder.HasMany(x => x.Questions)
            .WithOne(x => x.Quiz)
            .HasForeignKey(x => x.QuizId);

        builder.HasQueryFilter(x => x.DeletedAt == null);

        builder.HasIndex(x => new { x.CreatedByUserId, x.CreatedAt })
            .IsDescending(false, true)
            .HasFilter("[DeletedAt] IS NULL")
            .HasDatabaseName("IX_Quizzes_CreatedByUser_CreatedAt");
    }
}
