namespace CraftQuest.Application.Models.PrepPlus;

public sealed record PrepAccessGrantResult(
    DateTime? AccessExpiresAt,
    bool IsLifetimeAccess);
