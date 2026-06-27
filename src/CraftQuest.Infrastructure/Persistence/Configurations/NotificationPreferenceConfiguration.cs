using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class NotificationPreferenceConfiguration : IEntityTypeConfiguration<NotificationPreference>
{
    public void Configure(EntityTypeBuilder<NotificationPreference> builder)
    {
        builder.ToTable("NotificationPreferences", "core");
        builder.HasKey(x => x.NotificationPreferenceId);
        builder.Property(x => x.Type).HasMaxLength(60).IsRequired();

        builder.HasIndex(x => new { x.UserId, x.Type })
            .IsUnique()
            .HasDatabaseName("UQ_NotificationPreferences_User_Type");

        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
