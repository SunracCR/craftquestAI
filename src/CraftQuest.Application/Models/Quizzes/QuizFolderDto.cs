namespace CraftQuest.Application.Models.Quizzes;

public sealed class QuizFolderDto
{
    public required Guid QuizFolderId { get; init; }
    public required string Name { get; init; }
    public Guid? ParentFolderId { get; init; }
    public required int Depth { get; init; }
    public required int SortOrder { get; init; }
    public required int QuizCount { get; init; }
}
