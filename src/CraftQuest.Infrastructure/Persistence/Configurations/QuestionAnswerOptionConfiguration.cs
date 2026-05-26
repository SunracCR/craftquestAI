using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class QuestionAnswerOptionConfiguration : IEntityTypeConfiguration<QuestionAnswerOption>
{
    public void Configure(EntityTypeBuilder<QuestionAnswerOption> builder)
    {
        builder.ToTable("QuestionAnswerOptions", "quiz");
        builder.HasKey(x => x.AnswerOptionId);
        builder.Property(x => x.StableKey).HasMaxLength(100).IsRequired();
    }
}
