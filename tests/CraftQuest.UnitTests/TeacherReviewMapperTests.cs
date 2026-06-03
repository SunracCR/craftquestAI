using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Media;
using CraftQuest.Application.Services.Teacher;
using CraftQuest.Domain.Entities;

namespace CraftQuest.UnitTests;

public class TeacherReviewMapperTests
{
    private static readonly StubMediaService Media = new();
    /// <summary>TST-TCH-001: teacher review shows answers in session snapshot order, not canonical A,B sort.</summary>
    [Fact]
    public void MapReview_TST_TCH_001_PreservesShuffledAnswerSnapshotOrder()
    {
        var sessionId = Guid.NewGuid();
        var optionB = Guid.NewGuid();
        var optionA = Guid.NewGuid();
        var session = new PracticeSession
        {
            PracticeSessionId = sessionId,
            StudentUserId = Guid.NewGuid(),
            QuizId = Guid.NewGuid(),
            Status = "finished",
            ScoreObtained = 1,
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
                    QuestionTextSnapshot = "Q1",
                    DisplayOrder = 1,
                    PointsPossible = 1,
                    AnswerStatus = "answered",
                    AnswerOptionSnapshots =
                    [
                        new PracticeAnswerOptionSnapshot
                        {
                            AnswerOptionId = optionB,
                            DisplayOrder = 1,
                            DisplayLabel = "B",
                            AnswerTextSnapshot = "Second shown",
                        },
                        new PracticeAnswerOptionSnapshot
                        {
                            AnswerOptionId = optionA,
                            DisplayOrder = 2,
                            DisplayLabel = "A",
                            AnswerTextSnapshot = "First shown",
                            WasSelected = true,
                            IsCorrectSnapshot = true,
                        },
                    ],
                },
            ],
        };

        var review = TeacherReviewMapper.MapReview(session, Media);
        var answers = review.Questions[0].AnswersAsDisplayedToStudent;

        Assert.Equal(2, answers.Count);
        Assert.Equal("B", answers[0].DisplayLabel);
        Assert.Equal("Second shown", answers[0].Text);
        Assert.Equal("A", answers[1].DisplayLabel);
        Assert.True(answers[1].WasSelected);
    }

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
