using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class ClassMemberConfiguration : IEntityTypeConfiguration<ClassMember>
{
    public void Configure(EntityTypeBuilder<ClassMember> builder)
    {
        builder.ToTable("ClassMembers", "teacher");
        builder.HasKey(x => x.ClassMemberId);
        builder.Property(x => x.MemberRole).HasMaxLength(40).IsRequired();
        builder.Property(x => x.Status).HasMaxLength(30).IsRequired();
        builder.HasIndex(x => new { x.ClassId, x.UserId }).IsUnique();

        builder.HasOne(x => x.Class)
            .WithMany(c => c.Members)
            .HasForeignKey(x => x.ClassId);

        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId);
    }
}
