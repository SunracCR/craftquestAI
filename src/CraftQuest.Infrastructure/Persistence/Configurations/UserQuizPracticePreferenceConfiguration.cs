using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CraftQuest.Infrastructure.Persistence.Configurations;

public class UserQuizPracticePreferenceConfiguration
    : IEntityTypeConfiguration<UserQuizPracticePreference>
{
    public void Configure(EntityTypeBuilder<UserQuizPracticePreference> builder)
    {
        builder.ToTable("UserQuizPracticePreferences", "practice");
        builder.HasKey(x => new { x.UserId, x.QuizId });

        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Quiz)
            .WithMany()
            .HasForeignKey(x => x.QuizId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
