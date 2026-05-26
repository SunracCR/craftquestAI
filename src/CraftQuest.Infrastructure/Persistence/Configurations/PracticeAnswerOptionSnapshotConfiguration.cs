using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class PracticeAnswerOptionSnapshotConfiguration : IEntityTypeConfiguration<PracticeAnswerOptionSnapshot>
{
    public void Configure(EntityTypeBuilder<PracticeAnswerOptionSnapshot> builder)
    {
        builder.ToTable("PracticeAnswerOptionSnapshots", "practice");
        builder.HasKey(x => x.PracticeAnswerOptionSnapshotId);
        builder.Property(x => x.StableKeySnapshot).HasMaxLength(100);
        builder.Property(x => x.DisplayLabel).HasMaxLength(10).IsRequired();
    }
}
