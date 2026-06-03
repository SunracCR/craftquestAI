using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class QuestionJustificationSourceConfiguration : IEntityTypeConfiguration<QuestionJustificationSource>
{
    public void Configure(EntityTypeBuilder<QuestionJustificationSource> builder)
    {
        builder.ToTable("QuestionJustificationSources", "quiz");
        builder.HasKey(x => x.JustificationSourceId);
        builder.Property(x => x.SourceUrl).HasMaxLength(1500).IsRequired();
        builder.Property(x => x.SourceTitle).HasMaxLength(500);
        builder.Property(x => x.SourceProvider).HasMaxLength(100);
        builder.Property(x => x.Snippet).HasMaxLength(1000);

        builder.HasOne(x => x.Justification)
            .WithMany(x => x.Sources)
            .HasForeignKey(x => x.QuestionJustificationId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
