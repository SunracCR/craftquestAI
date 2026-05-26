using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class AnswerOptionStatsConfiguration : IEntityTypeConfiguration<AnswerOptionStats>
{
    public void Configure(EntityTypeBuilder<AnswerOptionStats> builder)
    {
        builder.ToTable("AnswerOptionStats", "analytics");
        builder.HasKey(x => x.AnswerOptionId);

        builder.HasOne(x => x.AnswerOption)
            .WithMany()
            .HasForeignKey(x => x.AnswerOptionId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
