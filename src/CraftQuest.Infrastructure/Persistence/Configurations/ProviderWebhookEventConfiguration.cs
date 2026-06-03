using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class ProviderWebhookEventConfiguration : IEntityTypeConfiguration<ProviderWebhookEvent>
{
    public void Configure(EntityTypeBuilder<ProviderWebhookEvent> builder)
    {
        builder.ToTable("ProviderWebhookEvents", "billing");
        builder.HasKey(x => x.ProviderWebhookEventId);
        builder.Property(x => x.ProviderCode).HasMaxLength(50).IsRequired();
        builder.Property(x => x.EventId).HasMaxLength(200).IsRequired();
        builder.Property(x => x.EventType).HasMaxLength(100).IsRequired();
        builder.HasIndex(x => new { x.ProviderCode, x.EventId }).IsUnique();
    }
}
