using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class QuestionImportErrorConfiguration : IEntityTypeConfiguration<QuestionImportError>
{
    public void Configure(EntityTypeBuilder<QuestionImportError> builder)
    {
        builder.ToTable("QuestionImportErrors", "importing");
        builder.HasKey(x => x.QuestionImportErrorId);
        builder.Property(x => x.FieldName).HasMaxLength(160);
        builder.Property(x => x.ErrorCode).HasMaxLength(80).IsRequired();
        builder.Property(x => x.ErrorMessage).HasMaxLength(1000).IsRequired();
        builder.Property(x => x.Severity).HasMaxLength(20).IsRequired();

        builder.HasOne(x => x.Row)
            .WithMany()
            .HasForeignKey(x => x.QuestionImportRowId);
    }
}
