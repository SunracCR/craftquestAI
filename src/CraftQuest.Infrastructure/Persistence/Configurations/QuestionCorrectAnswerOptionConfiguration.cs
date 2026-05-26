using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class QuestionCorrectAnswerOptionConfiguration : IEntityTypeConfiguration<QuestionCorrectAnswerOption>
{
    public void Configure(EntityTypeBuilder<QuestionCorrectAnswerOption> builder)
    {
        builder.ToTable("QuestionCorrectAnswerOptions", "quiz");
        builder.HasKey(x => new { x.QuestionId, x.AnswerOptionId });

        builder.HasOne(x => x.AnswerOption)
            .WithMany()
            .HasForeignKey(x => x.AnswerOptionId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
