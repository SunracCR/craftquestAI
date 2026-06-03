using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class PrepSampleQuestionConfiguration : IEntityTypeConfiguration<PrepSampleQuestion>
{
    public void Configure(EntityTypeBuilder<PrepSampleQuestion> builder)
    {
        builder.ToTable("PrepSampleQuestions", "catalog");
        builder.HasKey(x => new { x.CatalogItemId, x.QuestionId });

        builder.HasOne(x => x.CatalogItem)
            .WithMany(x => x.SampleQuestions)
            .HasForeignKey(x => x.CatalogItemId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Question)
            .WithMany()
            .HasForeignKey(x => x.QuestionId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
