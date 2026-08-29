namespace CraftQuest.Application.Models.PrepPlus;

public sealed class PrepQuizSectionDto
{
    public required Guid SectionId { get; init; }
    public required string Name { get; init; }
    public required int SortOrder { get; init; }
    public required int QuestionCount { get; init; }
    public IReadOnlyList<PrepQuizTopicDto> Topics { get; init; } = [];
}

public sealed class PrepQuizTopicDto
{
    public required Guid TopicId { get; init; }
    public required Guid SectionId { get; init; }
    public required string Name { get; init; }
    public required int SortOrder { get; init; }
    public required int QuestionCount { get; init; }
}

public sealed class PrepQuestionBankQuestionDto
{
    public required Guid QuestionId { get; init; }
    public required int SortOrder { get; init; }
    public required string PromptPreview { get; init; }
    public Guid? SectionId { get; init; }
    public Guid? TopicId { get; init; }
    public string? Difficulty { get; init; }
}

public sealed class PrepQuestionBankDto
{
    public required Guid CatalogItemId { get; init; }
    public required Guid QuizId { get; init; }
    public required bool SupportsCustomPractice { get; init; }
    public required int UntaggedQuestionCount { get; init; }
    public IReadOnlyList<PrepQuizSectionDto> Sections { get; init; } = [];
    public IReadOnlyList<PrepQuestionBankQuestionDto> Questions { get; init; } = [];
}

public class UpsertPrepQuizSectionRequest
{
    public string Name { get; set; } = string.Empty;
    public int SortOrder { get; set; }
}

public class UpsertPrepQuizTopicRequest
{
    public Guid SectionId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int SortOrder { get; set; }
}

public class TagPrepQuestionRequest
{
    public Guid QuestionId { get; set; }
    public Guid? SectionId { get; set; }
    public Guid? TopicId { get; set; }
    public string? Difficulty { get; set; }
}

public class BulkTagPrepQuestionsRequest
{
    public List<TagPrepQuestionRequest> Questions { get; set; } = [];
}

public class SetPrepCustomPracticeRequest
{
    public bool SupportsCustomPractice { get; set; }
}

public sealed class PrepPracticeSectionPublicDto
{
    public required Guid SectionId { get; init; }
    public required string Name { get; init; }
    public required int QuestionCount { get; init; }
    public IReadOnlyList<PrepPracticeTopicPublicDto> Topics { get; init; } = [];
}

public sealed class PrepPracticeTopicPublicDto
{
    public required Guid TopicId { get; init; }
    public required string Name { get; init; }
    public required int QuestionCount { get; init; }
}

public sealed class PrepPracticePoolDto
{
    public required int AvailableQuestionCount { get; init; }
    public required int MaxQuestionCount { get; init; }
}
