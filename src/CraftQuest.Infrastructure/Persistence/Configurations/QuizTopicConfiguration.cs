using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class QuizTopicConfiguration : IEntityTypeConfiguration<QuizTopic>
{
    public void Configure(EntityTypeBuilder<QuizTopic> builder)
    {
        builder.ToTable("QuizTopics", "quiz");
        builder.HasKey(x => x.QuizTopicId);
        builder.Property(x => x.Name).HasMaxLength(160).IsRequired();
        builder.HasIndex(x => new { x.QuizSectionId, x.Name }).IsUnique();

        builder.HasOne(x => x.Quiz)
            .WithMany()
            .HasForeignKey(x => x.QuizId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Section)
            .WithMany(x => x.Topics)
            .HasForeignKey(x => x.QuizSectionId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
