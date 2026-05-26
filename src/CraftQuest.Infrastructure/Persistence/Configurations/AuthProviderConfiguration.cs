using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class AuthProviderConfiguration : IEntityTypeConfiguration<AuthProvider>
{
    public void Configure(EntityTypeBuilder<AuthProvider> builder)
    {
        builder.ToTable("AuthProviders", "core");
        builder.HasKey(x => x.AuthProviderId);
        builder.Property(x => x.ProviderCode).HasMaxLength(50).IsRequired();
        builder.Property(x => x.ProviderSubject).HasMaxLength(300).IsRequired();

        builder.HasOne(x => x.User)
            .WithMany(x => x.AuthProviders)
            .HasForeignKey(x => x.UserId);
    }
}
