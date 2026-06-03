using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.IntegrationTests;

internal static class IntegrationTestDataSeeder
{
    public static void Seed(CraftQuestDbContext db)
    {
        if (!db.Roles.Any(r => r.Code == RoleCodes.Student))
        {
            db.Roles.Add(new Role { Code = RoleCodes.Student, Name = "Student" });
        }

        if (!db.Plans.Any(p => p.Code == "free"))
        {
            db.Plans.Add(new Plan
            {
                Code = "free",
                Name = "Free",
                MaxQuizzes = 2,
                MaxQuestionsPerQuiz = 50,
                MonthlyAiCredits = 20,
                MonthlyShareCodes = 2,
                IsActive = true,
            });
        }

        db.SaveChanges();
    }
}
