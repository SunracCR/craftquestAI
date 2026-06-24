using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class PasswordChangeTokenConfiguration : IEntityTypeConfiguration<PasswordChangeToken>
{
    public void Configure(EntityTypeBuilder<PasswordChangeToken> builder)
    {
        builder.ToTable("PasswordChangeTokens", "core");
        builder.HasKey(x => x.PasswordChangeTokenId);
        builder.Property(x => x.TokenHash).HasMaxLength(128).IsRequired();
        builder.Property(x => x.NewPasswordHash).HasColumnType("VARBINARY(256)").IsRequired();
        builder.HasIndex(x => x.TokenHash);
        builder.HasIndex(x => new { x.UserId, x.UsedAt });

        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
