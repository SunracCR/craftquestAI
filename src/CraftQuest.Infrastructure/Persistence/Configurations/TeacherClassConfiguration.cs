using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class TeacherClassConfiguration : IEntityTypeConfiguration<TeacherClass>
{
    public void Configure(EntityTypeBuilder<TeacherClass> builder)
    {
        builder.ToTable("Classes", "teacher");
        builder.HasKey(x => x.ClassId);
        builder.Property(x => x.Name).HasMaxLength(180).IsRequired();
        builder.Property(x => x.Status).HasMaxLength(30).IsRequired();

        builder.HasOne(x => x.TeacherUser)
            .WithMany()
            .HasForeignKey(x => x.TeacherUserId);
    }
}
