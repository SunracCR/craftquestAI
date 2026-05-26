using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class CreditLedgerEntryConfiguration : IEntityTypeConfiguration<CreditLedgerEntry>
{
    public void Configure(EntityTypeBuilder<CreditLedgerEntry> builder)
    {
        builder.ToTable("CreditLedger", "billing");
        builder.HasKey(x => x.CreditLedgerId);
        builder.Property(x => x.CreditType).HasMaxLength(40).IsRequired();
        builder.Property(x => x.Reason).HasMaxLength(100).IsRequired();
        builder.Property(x => x.ReferenceType).HasMaxLength(80);

        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId);
    }
}
