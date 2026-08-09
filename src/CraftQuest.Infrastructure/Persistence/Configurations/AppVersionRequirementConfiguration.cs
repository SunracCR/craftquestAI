using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class AppVersionRequirementConfiguration : IEntityTypeConfiguration<AppVersionRequirement>
{
    public void Configure(EntityTypeBuilder<AppVersionRequirement> builder)
    {
        builder.ToTable("AppVersionRequirements", "core");
        builder.HasKey(x => x.AppVersionRequirementId);

        builder.Property(x => x.Platform).HasMaxLength(20).IsRequired();
        builder.HasIndex(x => x.Platform).IsUnique();

        builder.Property(x => x.MinSupportedVersion).HasMaxLength(30).IsRequired();
        builder.Property(x => x.LatestVersion).HasMaxLength(30);
        builder.Property(x => x.UpdateUrl).HasMaxLength(500).IsRequired();
        builder.Property(x => x.Message).HasMaxLength(1000);
    }
}
