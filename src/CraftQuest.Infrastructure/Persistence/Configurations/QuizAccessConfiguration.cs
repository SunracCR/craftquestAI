using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class QuizAccessConfiguration : IEntityTypeConfiguration<QuizAccess>
{
    public void Configure(EntityTypeBuilder<QuizAccess> builder)
    {
        builder.ToTable("QuizAccesses", "sharing");
        builder.HasKey(x => x.QuizAccessId);
        builder.Property(x => x.AccessType).HasMaxLength(40).IsRequired();

        builder.HasIndex(x => new { x.UserId, x.QuizId, x.ClassId, x.AssignmentId })
            .IsUnique();

        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId);

        builder.HasOne(x => x.Quiz)
            .WithMany()
            .HasForeignKey(x => x.QuizId);

        builder.HasOne(x => x.GrantedByShareCode)
            .WithMany()
            .HasForeignKey(x => x.GrantedByShareCodeId);
    }
}
