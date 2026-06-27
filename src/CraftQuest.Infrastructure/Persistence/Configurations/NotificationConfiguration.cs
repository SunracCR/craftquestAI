using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class NotificationConfiguration : IEntityTypeConfiguration<Notification>
{
    public void Configure(EntityTypeBuilder<Notification> builder)
    {
        builder.ToTable("Notifications", "core");
        builder.HasKey(x => x.NotificationId);
        builder.Property(x => x.Type).HasMaxLength(60).IsRequired();
        builder.Property(x => x.Title).HasMaxLength(200).IsRequired();
        builder.Property(x => x.Body).HasMaxLength(1000).IsRequired();
        builder.Property(x => x.DataJson).HasMaxLength(4000);
        builder.Property(x => x.DedupKey).HasMaxLength(200);

        builder.HasIndex(x => new { x.UserId, x.IsRead, x.CreatedAt })
            .HasDatabaseName("IX_Notifications_User_Read_CreatedAt");

        builder.HasIndex(x => new { x.UserId, x.DedupKey })
            .IsUnique()
            .HasFilter("[DedupKey] IS NOT NULL")
            .HasDatabaseName("UQ_Notifications_User_DedupKey");

        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
