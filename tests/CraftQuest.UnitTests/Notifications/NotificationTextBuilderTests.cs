using CraftQuest.Application.Models.Notifications;
using CraftQuest.Domain.Constants;
using CraftQuest.Infrastructure.Notifications;

namespace CraftQuest.UnitTests.Notifications;

public class NotificationTextBuilderTests
{
    [Theory]
    [InlineData("es", "Cuestionario compartido")]
    [InlineData("en", "Quiz shared with you")]
    [InlineData("pt", "Questionario compartilhado")]
    public void Build_QuizShared_UsesLanguage(string language, string expectedTitleFragment)
    {
        var (title, body) = NotificationTextBuilder.Build(
            NotificationTypes.QuizShared,
            language,
            new NotificationPayload { QuizTitle = "Algebra" });

        Assert.Contains(expectedTitleFragment, title, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("Algebra", body);
    }

    [Fact]
    public void Build_AssignmentDueSoon_IncludesDueLabel()
    {
        var (title, body) = NotificationTextBuilder.Build(
            NotificationTypes.AssignmentDueSoon,
            "en",
            new NotificationPayload
            {
                AssignmentTitle = "Homework 1",
                DueAtLabel = "2026-06-26",
            });

        Assert.Contains("due soon", title, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("Homework 1", body);
        Assert.Contains("2026-06-26", body);
    }

    [Fact]
    public void Build_MembershipExpiring_IncludesDaysRemaining()
    {
        var (_, body) = NotificationTextBuilder.Build(
            NotificationTypes.MembershipExpiring,
            "es",
            new NotificationPayload
            {
                PlanName = "Pro",
                DaysRemaining = 3,
            });

        Assert.Contains("Pro", body);
        Assert.Contains("3", body);
    }
}
