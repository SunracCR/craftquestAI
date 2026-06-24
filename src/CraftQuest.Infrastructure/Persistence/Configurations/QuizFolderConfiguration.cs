using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class QuizFolderConfiguration : IEntityTypeConfiguration<QuizFolder>
{
    public void Configure(EntityTypeBuilder<QuizFolder> builder)
    {
        builder.ToTable("QuizFolders", "quiz");
        builder.HasKey(x => x.QuizFolderId);
        builder.Property(x => x.Name).HasMaxLength(160).IsRequired();
        builder.Property(x => x.Depth).IsRequired();

        builder.HasQueryFilter(x => x.DeletedAt == null);

        builder.HasIndex(x => new { x.OwnerUserId, x.ParentFolderId, x.SortOrder })
            .HasFilter("[DeletedAt] IS NULL")
            .HasDatabaseName("IX_QuizFolders_Owner");
    }
}
