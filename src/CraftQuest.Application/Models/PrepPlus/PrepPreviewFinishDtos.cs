using CraftQuest.Application.Models.Teacher;

namespace CraftQuest.Application.Models.PrepPlus;

public class PrepPreviewFinishAnswerDto
{
    public Guid QuestionId { get; set; }
    public List<Guid> SelectedAnswerOptionIds { get; set; } = [];
}

public class PrepPreviewFinishRequest
{
    public List<PrepPreviewFinishAnswerDto> Answers { get; set; } = [];
    public int? DurationSeconds { get; set; }
}

public sealed class PrepPreviewFinishResultDto
{
    public required Guid CatalogItemId { get; init; }
    public required decimal ScoreObtained { get; init; }
    public required decimal ScorePossible { get; init; }
    public required decimal Percentage { get; init; }
    public required int CorrectAnswers { get; init; }
    public required int IncorrectAnswers { get; init; }
    public required int OmittedAnswers { get; init; }
    public required TeacherPracticeReviewDto Review { get; init; }
}
