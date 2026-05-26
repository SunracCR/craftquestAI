namespace CraftQuest.Application.Models;

public sealed class AppStatusDto
{
    public required string Service { get; init; }
    public required string Version { get; init; }
    public required string Database { get; init; }
    public required int RoleCount { get; init; }
    public required int QuestionTypeCount { get; init; }
    public required int PlanCount { get; init; }
}