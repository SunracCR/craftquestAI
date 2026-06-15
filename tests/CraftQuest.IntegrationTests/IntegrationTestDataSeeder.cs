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

        if (!db.QuestionTypes.Any(t => t.Code == "single_choice"))
        {
            db.QuestionTypes.AddRange(
                new QuestionType
                {
                    Code = "single_choice",
                    Name = "Single choice",
                    SupportsMultipleCorrectAnswers = false,
                    RequiresOptions = true,
                    IsActive = true,
                },
                new QuestionType
                {
                    Code = "multiple_choice",
                    Name = "Multiple choice",
                    SupportsMultipleCorrectAnswers = true,
                    RequiresOptions = true,
                    IsActive = true,
                },
                new QuestionType
                {
                    Code = "true_false",
                    Name = "True/False",
                    SupportsMultipleCorrectAnswers = false,
                    RequiresOptions = true,
                    IsActive = true,
                });
        }

        db.SaveChanges();
    }
}
