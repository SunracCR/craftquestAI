using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class QuestionJustificationConfiguration : IEntityTypeConfiguration<QuestionJustification>
{
    public void Configure(EntityTypeBuilder<QuestionJustification> builder)
    {
        builder.ToTable("QuestionJustifications", "quiz");
        builder.HasKey(x => x.QuestionJustificationId);
        builder.Property(x => x.Status).HasMaxLength(40).IsRequired();
    }
}
