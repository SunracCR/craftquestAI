using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class GuestVisitConfiguration : IEntityTypeConfiguration<GuestVisit>
{
    public void Configure(EntityTypeBuilder<GuestVisit> builder)
    {
        builder.ToTable("GuestVisits", "guest");
        builder.HasKey(x => x.GuestVisitId);
        builder.Property(x => x.Token).HasMaxLength(64).IsRequired();
        builder.HasIndex(x => x.Token).IsUnique();
        builder.HasIndex(x => x.ExpiresAt);

        builder.HasOne(x => x.Quiz)
            .WithMany()
            .HasForeignKey(x => x.QuizId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(x => x.PracticeSessions)
            .WithOne(x => x.GuestVisit)
            .HasForeignKey(x => x.GuestVisitId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
