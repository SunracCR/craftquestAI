using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class PurchaseConfiguration : IEntityTypeConfiguration<Purchase>
{
    public void Configure(EntityTypeBuilder<Purchase> builder)
    {
        builder.ToTable("Purchases", "billing");
        builder.HasKey(x => x.PurchaseId);
        builder.Property(x => x.ProductCode).HasMaxLength(100);
        builder.Property(x => x.ProductType).HasMaxLength(40);
        builder.Property(x => x.ProviderCode).HasMaxLength(50);
        builder.Property(x => x.ProviderTransactionId).HasMaxLength(300);
        builder.Property(x => x.CurrencyCode).HasMaxLength(10);
        builder.Property(x => x.Status).HasMaxLength(30);
        builder.Property(x => x.Amount).HasPrecision(12, 2);
    }
}
