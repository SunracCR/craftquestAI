using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class QuestionStatsConfiguration : IEntityTypeConfiguration<QuestionStats>
{
    public void Configure(EntityTypeBuilder<QuestionStats> builder)
    {
        builder.ToTable("QuestionStats", "analytics");
        builder.HasKey(x => x.QuestionId);
        builder.Property(x => x.AverageTimeSeconds).HasPrecision(12, 2);

        builder.HasOne(x => x.Question)
            .WithMany()
            .HasForeignKey(x => x.QuestionId);
    }
}
