using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("Users", "core");
        builder.HasKey(x => x.UserId);
        builder.Property(x => x.Email).HasMaxLength(320).IsRequired();
        builder.Property(x => x.EmailNormalized)
            .HasMaxLength(320)
            .HasComputedColumnSql("UPPER([Email])", stored: true);

        builder.HasIndex(x => x.EmailNormalized)
            .IsUnique()
            .HasDatabaseName("UQ_Users_EmailNormalized");
        builder.Property(x => x.ExternalSubject).HasMaxLength(200);
        builder.Property(x => x.DisplayName).HasMaxLength(160);
        builder.Property(x => x.AvatarId).HasMaxLength(40);
        builder.Property(x => x.PreferredLanguage).HasMaxLength(5);
        builder.Property(x => x.PhotoUrl).HasMaxLength(1000);
        builder.Property(x => x.CountryCode).HasMaxLength(10);
        builder.Property(x => x.PhoneNumber).HasMaxLength(40);
        builder.Property(x => x.Status).HasMaxLength(30).IsRequired();

        builder.HasQueryFilter(x => x.DeletedAt == null);
    }
}
