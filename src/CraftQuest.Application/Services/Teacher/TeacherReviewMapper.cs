using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Teacher;
using CraftQuest.Domain.Entities;

namespace CraftQuest.Application.Services.Teacher;

public static class TeacherReviewMapper
{
    private const string QuestionImageKey = "QUESTION_IMAGE";

    public static TeacherPracticeReviewDto MapReview(
        PracticeSession session,
        IMediaService mediaService,
        bool revealCorrectAnswers = true)
    {
        var questions = session.QuestionSnapshots
            .OrderBy(q => q.DisplayOrder)
            .Select(q => MapQuestion(q, mediaService, revealCorrectAnswers))
            .ToList();

        return new TeacherPracticeReviewDto
        {
            PracticeSessionId = session.PracticeSessionId,
            QuizId = session.QuizId,
            Status = session.Status,
            ScoreObtained = session.ScoreObtained,
            ScorePossible = session.ScorePossible,
            FinishedAt = session.FinishedAt,
            Student = new TeacherStudentDto
            {
                UserId = session.StudentUserId ?? Guid.Empty,
                DisplayName = session.StudentUser?.DisplayName ?? session.StudentUser?.Email,
            },
            Questions = questions,
            RevealCorrectAnswers = revealCorrectAnswers,
        };
    }

    private static TeacherPracticeQuestionReviewDto MapQuestion(
        PracticeQuestionSnapshot q,
        IMediaService mediaService,
        bool revealCorrectAnswers)
    {
        var snapshots = q.AnswerOptionSnapshots.OrderBy(a => a.DisplayOrder).ToList();
        var stemSnapshot = snapshots.FirstOrDefault(IsQuestionImageStem);
        var answerSnapshots = snapshots.Where(a => !IsQuestionImageStem(a)).ToList();

        return new TeacherPracticeQuestionReviewDto
        {
            PracticeQuestionSnapshotId = q.PracticeQuestionSnapshotId,
            QuestionId = q.QuestionId,
            DisplayOrder = q.DisplayOrder,
            QuestionText = q.QuestionTextSnapshot,
            QuestionMediaUrl = stemSnapshot?.MediaAssetIdSnapshot is Guid stemMediaId
                ? mediaService.BuildPublicUrl(stemMediaId)
                : null,
            IsCorrect = revealCorrectAnswers ? q.IsCorrect : null,
            PointsAwarded = q.PointsAwarded,
            PointsPossible = q.PointsPossible,
            AnswerStatus = q.AnswerStatus,
            AnswersAsDisplayedToStudent = answerSnapshots
                .Select(a => new TeacherAnswerOptionReviewDto
                {
                    AnswerOptionId = a.AnswerOptionId,
                    StableKey = a.StableKeySnapshot,
                    DisplayOrder = a.DisplayOrder,
                    DisplayLabel = a.DisplayLabel,
                    Text = a.AnswerTextSnapshot,
                    MediaUrl = a.MediaAssetIdSnapshot is Guid mediaId
                        ? mediaService.BuildPublicUrl(mediaId)
                        : null,
                    WasSelected = a.WasSelected,
                    IsCorrect = revealCorrectAnswers && a.IsCorrectSnapshot,
                })
                .ToList(),
        };
    }

    private static bool IsQuestionImageStem(PracticeAnswerOptionSnapshot snapshot) =>
        string.Equals(
            snapshot.StableKeySnapshot,
            QuestionImageKey,
            StringComparison.OrdinalIgnoreCase);
}
