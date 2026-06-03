using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class UserSubscriptionConfiguration : IEntityTypeConfiguration<UserSubscription>
{
    public void Configure(EntityTypeBuilder<UserSubscription> builder)
    {
        builder.ToTable("UserSubscriptions", "billing");
        builder.HasKey(x => x.UserSubscriptionId);
        builder.Property(x => x.Status).HasMaxLength(30).IsRequired();
        builder.Property(x => x.ProviderCode).HasMaxLength(50);
        builder.Property(x => x.ProviderSubscriptionId).HasMaxLength(300);
        builder.Property(x => x.BillingCycle).HasMaxLength(20).IsRequired();
        builder.Property(x => x.AutoRenewEnabled).HasDefaultValue(true);
        builder.Property(x => x.CancelAtPeriodEnd).HasDefaultValue(false);

        builder.HasOne(x => x.Plan)
            .WithMany()
            .HasForeignKey(x => x.PlanId);

        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId);
    }
}
