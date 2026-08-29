using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class QuizSectionConfiguration : IEntityTypeConfiguration<QuizSection>
{
    public void Configure(EntityTypeBuilder<QuizSection> builder)
    {
        builder.ToTable("QuizSections", "quiz");
        builder.HasKey(x => x.QuizSectionId);
        builder.Property(x => x.Name).HasMaxLength(160).IsRequired();
        builder.HasIndex(x => new { x.QuizId, x.Name }).IsUnique();

        builder.HasOne(x => x.Quiz)
            .WithMany()
            .HasForeignKey(x => x.QuizId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(x => x.Questions)
            .WithOne(x => x.QuizSection)
            .HasForeignKey(x => x.QuizSectionId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
