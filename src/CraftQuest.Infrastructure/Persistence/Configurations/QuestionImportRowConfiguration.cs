using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class QuestionImportRowConfiguration : IEntityTypeConfiguration<QuestionImportRow>
{
    public void Configure(EntityTypeBuilder<QuestionImportRow> builder)
    {
        builder.ToTable("QuestionImportRows", "importing");
        builder.HasKey(x => x.QuestionImportRowId);
        builder.Property(x => x.Status).HasMaxLength(40).IsRequired();
        builder.Property(x => x.RawDataJson);
        builder.Property(x => x.CqifQuestionJson);

        builder.HasOne(x => x.CreatedQuestion)
            .WithMany()
            .HasForeignKey(x => x.CreatedQuestionId);
    }
}
