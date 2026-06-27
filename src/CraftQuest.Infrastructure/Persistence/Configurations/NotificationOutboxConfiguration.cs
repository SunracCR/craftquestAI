using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class NotificationOutboxConfiguration : IEntityTypeConfiguration<NotificationOutbox>
{
    public void Configure(EntityTypeBuilder<NotificationOutbox> builder)
    {
        builder.ToTable("NotificationOutbox", "core");
        builder.HasKey(x => x.NotificationOutboxId);
        builder.Property(x => x.EventType).HasMaxLength(60).IsRequired();
        builder.Property(x => x.PayloadJson).HasMaxLength(4000).IsRequired();
        builder.Property(x => x.Status).HasMaxLength(30).IsRequired();

        builder.HasIndex(x => new { x.Status, x.CreatedAt })
            .HasDatabaseName("IX_NotificationOutbox_Status_CreatedAt");
    }
}
