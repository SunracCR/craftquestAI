using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.PrepPlus;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CraftQuest.UnitTests.PrepPlus;

public class PrepPlusAdminServiceLinkableQuizzesTests
{
    [Fact]
    public async Task ListLinkableQuizzes_IncludesCuratedQuiz_WhenAuthorIsNotContentAdmin()
    {
        await using var db = CreateDb();
        var requestingAdminId = Guid.NewGuid();
        var teacherAuthorId = Guid.NewGuid();
        var quizId = Guid.NewGuid();

        db.Quizzes.Add(new Quiz
        {
            QuizId = quizId,
            CreatedByUserId = teacherAuthorId,
            Title = "Examen UNAM curado",
            Visibility = PrepPlusConstants.CuratedVisibility,
            IsCurated = true,
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        var service = CreateService(db);
        var result = await service.ListLinkableQuizzesAsync(requestingAdminId);

        Assert.Single(result);
        Assert.Equal(quizId, result[0].QuizId);
    }

    [Fact]
    public async Task ListLinkableQuizzes_IncludesOwnQuiz_WhenRequestingUserIsAuthor()
    {
        await using var db = CreateDb();
        var adminId = Guid.NewGuid();
        var quizId = Guid.NewGuid();

        db.Quizzes.Add(new Quiz
        {
            QuizId = quizId,
            CreatedByUserId = adminId,
            Title = "Mi borrador Prep+",
            Visibility = "private",
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        var service = CreateService(db);
        var result = await service.ListLinkableQuizzesAsync(adminId);

        Assert.Single(result);
        Assert.Equal(quizId, result[0].QuizId);
    }

    [Fact]
    public async Task ListLinkableQuizzes_ExcludesQuizAlreadyInCatalog()
    {
        await using var db = CreateDb();
        var adminId = Guid.NewGuid();
        var quizId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var rootId = Guid.NewGuid();

        db.PrepCategories.AddRange(
            new PrepCategory
            {
                CategoryId = rootId,
                Name = "México",
                Slug = "mexico",
                CategoryType = PrepPlusConstants.CategoryTypes.Geographic,
                SortOrder = 1,
                IsActive = true,
            },
            new PrepCategory
            {
                CategoryId = categoryId,
                ParentCategoryId = rootId,
                Name = "UNAM",
                Slug = "unam",
                CategoryType = PrepPlusConstants.CategoryTypes.Geographic,
                SortOrder = 1,
                IsActive = true,
            });

        db.Quizzes.Add(new Quiz
        {
            QuizId = quizId,
            CreatedByUserId = adminId,
            Title = "Ya en catálogo",
            Visibility = PrepPlusConstants.CuratedVisibility,
            IsCurated = true,
            CreatedAt = DateTime.UtcNow,
        });

        db.PrepCatalogItems.Add(new PrepCatalogItem
        {
            CatalogItemId = Guid.NewGuid(),
            QuizId = quizId,
            CategoryId = categoryId,
            IsPublished = true,
            CreatedByUserId = adminId,
            CreatedAt = DateTime.UtcNow,
        });

        await db.SaveChangesAsync();

        var service = CreateService(db);
        var result = await service.ListLinkableQuizzesAsync(adminId);

        Assert.Empty(result);
    }

    [Fact]
    public async Task CreateCatalogItem_AllowsCuratedQuiz_FromNonAdminAuthor()
    {
        await using var db = CreateDb();
        var adminId = Guid.NewGuid();
        var teacherAuthorId = Guid.NewGuid();
        var quizId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var rootId = Guid.NewGuid();

        db.PrepCategories.AddRange(
            new PrepCategory
            {
                CategoryId = rootId,
                Name = "México",
                Slug = "mexico",
                CategoryType = PrepPlusConstants.CategoryTypes.Geographic,
                SortOrder = 1,
                IsActive = true,
            },
            new PrepCategory
            {
                CategoryId = categoryId,
                ParentCategoryId = rootId,
                Name = "UNAM",
                Slug = "unam",
                CategoryType = PrepPlusConstants.CategoryTypes.Geographic,
                SortOrder = 1,
                IsActive = true,
            });

        db.Quizzes.Add(new Quiz
        {
            QuizId = quizId,
            CreatedByUserId = teacherAuthorId,
            Title = "Curado importado",
            Visibility = PrepPlusConstants.CuratedVisibility,
            IsCurated = true,
            CreatedAt = DateTime.UtcNow,
        });

        await db.SaveChangesAsync();

        var service = CreateService(db);
        var created = await service.CreateCatalogItemAsync(
            adminId,
            new CreatePrepCatalogItemRequest
            {
                QuizId = quizId,
                CategoryId = categoryId,
            });

        Assert.Equal(quizId, created.QuizId);
    }

    [Fact]
    public async Task CreateCatalogItem_RejectsPrivateQuiz_FromNonAdminAuthor()
    {
        await using var db = CreateDb();
        var adminId = Guid.NewGuid();
        var teacherAuthorId = Guid.NewGuid();
        var quizId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var rootId = Guid.NewGuid();

        db.PrepCategories.AddRange(
            new PrepCategory
            {
                CategoryId = rootId,
                Name = "México",
                Slug = "mexico",
                CategoryType = PrepPlusConstants.CategoryTypes.Geographic,
                SortOrder = 1,
                IsActive = true,
            },
            new PrepCategory
            {
                CategoryId = categoryId,
                ParentCategoryId = rootId,
                Name = "UNAM",
                Slug = "unam",
                CategoryType = PrepPlusConstants.CategoryTypes.Geographic,
                SortOrder = 1,
                IsActive = true,
            });

        db.Quizzes.Add(new Quiz
        {
            QuizId = quizId,
            CreatedByUserId = teacherAuthorId,
            Title = "Privado de profesor",
            Visibility = "private",
            CreatedAt = DateTime.UtcNow,
        });

        await db.SaveChangesAsync();

        var service = CreateService(db);
        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.CreateCatalogItemAsync(
                adminId,
                new CreatePrepCatalogItemRequest
                {
                    QuizId = quizId,
                    CategoryId = categoryId,
                }));

        Assert.Equal(PrepPlusErrorCodes.QuizNotEligible, ex.ErrorCode);
    }

    private static PrepPlusAdminService CreateService(CraftQuestDbContext db) =>
        new(
            db,
            Options.Create(new JoinLinkOptions
            {
                LinkBaseUrl = "https://craftquest.test",
            }));

    private static CraftQuestDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<CraftQuestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new CraftQuestDbContext(options);
    }
}
