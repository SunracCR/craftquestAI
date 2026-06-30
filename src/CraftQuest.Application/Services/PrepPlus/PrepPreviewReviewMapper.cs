using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Teacher;
using CraftQuest.Application.Services.Quizzes;
using CraftQuest.Domain.Entities;

namespace CraftQuest.Application.Services.PrepPlus;

public static class PrepPreviewReviewMapper
{
    private const string QuestionImageKey = "QUESTION_IMAGE";

    public static TeacherPracticeQuestionReviewDto MapQuestion(
        Question question,
        int displayOrder,
        IReadOnlySet<Guid> selectedIds,
        bool? isCorrect,
        decimal pointsAwarded,
        string answerStatus,
        IMediaService mediaService)
    {
        var options = question.AnswerOptions
            .Where(o => o.IsActive)
            .OrderBy(o => o.DefaultSortOrder)
            .ToList();

        var correctIds = question.CorrectAnswerOptions
            .Select(c => c.AnswerOptionId)
            .ToHashSet();

        var labels = AnswerGradingService.BuildDisplayLabels(options.Count);
        var stemOption = options.FirstOrDefault(IsQuestionImageStem);
        var answerOptions = options.Where(o => !IsQuestionImageStem(o)).ToList();

        return new TeacherPracticeQuestionReviewDto
        {
            PracticeQuestionSnapshotId = question.QuestionId,
            QuestionId = question.QuestionId,
            DisplayOrder = displayOrder,
            QuestionText = question.QuestionText,
            QuestionMediaUrl = stemOption?.MediaAssetId is Guid stemMediaId
                ? mediaService.BuildPublicUrl(stemMediaId)
                : null,
            IsCorrect = isCorrect,
            PointsAwarded = pointsAwarded,
            PointsPossible = question.Points,
            AnswerStatus = answerStatus,
            AnswersAsDisplayedToStudent = answerOptions
                .Select((option, index) => new TeacherAnswerOptionReviewDto
                {
                    AnswerOptionId = option.AnswerOptionId,
                    StableKey = option.StableKey,
                    DisplayOrder = index,
                    DisplayLabel = index < labels.Count ? labels[index] : AnswerGradingService.IndexToDisplayLabel(index),
                    Text = option.AnswerText,
                    MediaUrl = option.MediaAssetId is Guid mediaId
                        ? mediaService.BuildPublicUrl(mediaId)
                        : null,
                    WasSelected = selectedIds.Contains(option.AnswerOptionId),
                    IsCorrect = correctIds.Contains(option.AnswerOptionId),
                })
                .ToList(),
            JustificationText = question.Justification?.JustificationText,
            JustificationSources = QuestionJustificationMapper.ParseSnapshotSources(
                QuestionJustificationMapper.BuildPracticeSnapshot(question.Justification).SourcesJson),
        };
    }

    private static bool IsQuestionImageStem(QuestionAnswerOption option) =>
        string.Equals(option.StableKey, QuestionImageKey, StringComparison.OrdinalIgnoreCase);
}
