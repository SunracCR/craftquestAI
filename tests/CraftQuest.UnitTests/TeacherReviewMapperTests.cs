using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Media;
using CraftQuest.Application.Services.Teacher;
using CraftQuest.Domain.Entities;

namespace CraftQuest.UnitTests;

public class TeacherReviewMapperTests
{
    private static readonly StubMediaService Media = new();
    [Fact]
    public void MapReview_PreservesQuestionAndAnswerDisplayOrder()
    {
        var sessionId = Guid.NewGuid();
        var session = new PracticeSession
        {
            PracticeSessionId = sessionId,
            StudentUserId = Guid.NewGuid(),
            QuizId = Guid.NewGuid(),
            Status = "finished",
            ScoreObtained = 1,
            ScorePossible = 2,
            StudentUser = new User
            {
                UserId = Guid.NewGuid(),
                Email = "student@test.com",
                DisplayName = "Student A",
            },
            QuestionSnapshots =
            [
                new PracticeQuestionSnapshot
                {
                    PracticeQuestionSnapshotId = Guid.NewGuid(),
                    PracticeSessionId = sessionId,
                    QuestionId = Guid.NewGuid(),
                    QuestionTextSnapshot = "Second",
                    DisplayOrder = 2,
                    PointsPossible = 1,
                    AnswerStatus = "answered",
                    AnswerOptionSnapshots =
                    [
                        new PracticeAnswerOptionSnapshot
                        {
                            AnswerOptionId = Guid.NewGuid(),
                            DisplayOrder = 2,
                            DisplayLabel = "B",
                            IsCorrectSnapshot = false,
                        },
                        new PracticeAnswerOptionSnapshot
                        {
                            AnswerOptionId = Guid.NewGuid(),
                            DisplayOrder = 1,
                            DisplayLabel = "A",
                            WasSelected = true,
                            IsCorrectSnapshot = true,
                        },
                    ],
                },
                new PracticeQuestionSnapshot
                {
                    PracticeQuestionSnapshotId = Guid.NewGuid(),
                    PracticeSessionId = sessionId,
                    QuestionId = Guid.NewGuid(),
                    QuestionTextSnapshot = "First",
                    DisplayOrder = 1,
                    PointsPossible = 1,
                    AnswerStatus = "omitted",
                    AnswerOptionSnapshots =
                    [
                        new PracticeAnswerOptionSnapshot
                        {
                            AnswerOptionId = Guid.NewGuid(),
                            DisplayOrder = 1,
                            DisplayLabel = "A",
                        },
                    ],
                },
            ],
        };

        var review = TeacherReviewMapper.MapReview(session, Media);

        Assert.Equal(2, review.Questions.Count);
        Assert.Equal("First", review.Questions[0].QuestionText);
        Assert.Equal("Second", review.Questions[1].QuestionText);
        Assert.Equal("A", review.Questions[1].AnswersAsDisplayedToStudent[0].DisplayLabel);
        Assert.True(review.Questions[1].AnswersAsDisplayedToStudent[0].WasSelected);
    }

    [Fact]
    public void MapReview_ExposesQuestionStemAndAnswerMediaUrls()
    {
        var sessionId = Guid.NewGuid();
        var stemMediaId = Guid.NewGuid();
        var optionMediaId = Guid.NewGuid();
        var session = new PracticeSession
        {
            PracticeSessionId = sessionId,
            StudentUserId = Guid.NewGuid(),
            QuizId = Guid.NewGuid(),
            Status = "finished",
            ScoreObtained = 0,
            ScorePossible = 1,
            StudentUser = new User
            {
                UserId = Guid.NewGuid(),
                Email = "student@test.com",
            },
            QuestionSnapshots =
            [
                new PracticeQuestionSnapshot
                {
                    PracticeQuestionSnapshotId = Guid.NewGuid(),
                    PracticeSessionId = sessionId,
                    QuestionId = Guid.NewGuid(),
                    QuestionTextSnapshot = "Pick the animal",
                    DisplayOrder = 1,
                    PointsPossible = 1,
                    AnswerStatus = "answered",
                    AnswerOptionSnapshots =
                    [
                        new PracticeAnswerOptionSnapshot
                        {
                            AnswerOptionId = Guid.NewGuid(),
                            StableKeySnapshot = "QUESTION_IMAGE",
                            DisplayOrder = 0,
                            DisplayLabel = string.Empty,
                            MediaAssetIdSnapshot = stemMediaId,
                        },
                        new PracticeAnswerOptionSnapshot
                        {
                            AnswerOptionId = Guid.NewGuid(),
                            DisplayOrder = 1,
                            DisplayLabel = "A",
                            AnswerTextSnapshot = "Cat",
                            MediaAssetIdSnapshot = optionMediaId,
                            WasSelected = true,
                            IsCorrectSnapshot = true,
                        },
                    ],
                },
            ],
        };

        var review = TeacherReviewMapper.MapReview(session, Media);

        Assert.Equal($"https://media.test/{stemMediaId}", review.Questions[0].QuestionMediaUrl);
        Assert.Single(review.Questions[0].AnswersAsDisplayedToStudent);
        Assert.Equal($"https://media.test/{optionMediaId}", review.Questions[0].AnswersAsDisplayedToStudent[0].MediaUrl);
    }

    private sealed class StubMediaService : IMediaService
    {
        public string BuildPublicUrl(Guid mediaAssetId) => $"https://media.test/{mediaAssetId}";

        public Task<MediaAssetDto> UploadImageAsync(
            Guid userId,
            Stream content,
            string fileName,
            string contentType,
            long fileSize,
            string? altText = null,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task<(Stream Stream, string ContentType, string FileName)> OpenReadAsync(
            Guid mediaAssetId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();
    }
}
