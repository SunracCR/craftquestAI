using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class ShareCodeConfiguration : IEntityTypeConfiguration<ShareCode>
{
    public void Configure(EntityTypeBuilder<ShareCode> builder)
    {
        builder.ToTable("ShareCodes", "sharing");
        builder.HasKey(x => x.ShareCodeId);
        builder.Property(x => x.Code).HasMaxLength(80).IsRequired();
        builder.Property(x => x.CodeType).HasMaxLength(40).IsRequired();
        builder.Property(x => x.Status).HasMaxLength(30).IsRequired();
        builder.Property(x => x.AccessPolicy).HasMaxLength(30).IsRequired()
            .HasDefaultValue("registered_open");
        builder.HasIndex(x => x.Code).IsUnique();

        builder.HasIndex(x => x.QuizId)
            .IsUnique()
            .HasFilter("[AssignmentId] IS NULL AND [QuizId] IS NOT NULL")
            .HasDatabaseName("UQ_ShareCodes_Quiz_General");

        builder.HasOne(x => x.Quiz)
            .WithMany()
            .HasForeignKey(x => x.QuizId);

        builder.HasOne(x => x.CreatedByUser)
            .WithMany()
            .HasForeignKey(x => x.CreatedByUserId);
    }
}
