using CraftQuest.Application.Models.Practice;

namespace CraftQuest.Application.Models.Offline;

public sealed class OfflineEntitlementsDto
{
    public required bool CanDownloadOffline { get; init; }
    public int? MaxOfflineQuizzes { get; init; }
    public int? MaxOfflineStorageMb { get; init; }
}

public sealed class OfflineQuizPackageDto
{
    public required Guid QuizId { get; init; }
    public required string Title { get; init; }
    public string? Description { get; init; }
    public required string ContentVersion { get; init; }
    public required DateTime GeneratedAt { get; init; }
    public required DateTime ExpiresAt { get; init; }
    /// <summary>Base64 AES-256 key; client must store in secure storage, not in SQLite.</summary>
    public required string PackageKeyBase64 { get; init; }
    public required bool RandomizeQuestions { get; init; }
    public required bool DefaultRandomizeAnswerOptions { get; init; }
    public required string WatermarkToken { get; init; }
    public required IReadOnlyList<OfflinePackageQuestionDto> Questions { get; init; }
    public required IReadOnlyList<OfflinePackageMediaAssetDto> MediaAssets { get; init; }
    public required OfflineEntitlementsDto Entitlements { get; init; }
}

public sealed class OfflinePackageQuestionDto
{
    public required Guid QuestionId { get; init; }
    public required int SortOrder { get; init; }
    public required string QuestionText { get; init; }
    public required string QuestionType { get; init; }
    public required decimal Points { get; init; }
    public required bool RandomizeAnswerOptions { get; init; }
    public required string ScoringPolicy { get; init; }
    public required bool SupportsMultipleCorrectAnswers { get; init; }
    public Guid? QuestionMediaAssetId { get; init; }
    /// <summary>Base64 AES-GCM blob of JSON array of correct AnswerOptionIds.</summary>
    public required string CorrectAnswerBlob { get; init; }
    public required IReadOnlyList<OfflinePackageAnswerOptionDto> AnswerOptions { get; init; }
}

public sealed class OfflinePackageAnswerOptionDto
{
    public required Guid AnswerOptionId { get; init; }
    public required string StableKey { get; init; }
    public required int DefaultSortOrder { get; init; }
    public string? AnswerText { get; init; }
    public Guid? MediaAssetId { get; init; }
}

public sealed class OfflinePackageMediaAssetDto
{
    public required Guid MediaAssetId { get; init; }
    public required string DownloadUrl { get; init; }
    public string? ContentType { get; init; }
    public long? FileSizeBytes { get; init; }
}

public sealed class OfflineSyncRequest
{
    public Guid ClientSessionId { get; set; }
    public Guid QuizId { get; set; }
    public string ContentVersion { get; set; } = string.Empty;
    public DateTime StartedAt { get; set; }
    public DateTime FinishedAt { get; set; }
    public bool ShowElapsedTimer { get; set; }
    public decimal? LocalScoreObtained { get; set; }
    public decimal? LocalScorePossible { get; set; }
    public List<OfflineSyncAnswerDto> Answers { get; set; } = [];
}

public sealed class OfflineSyncAnswerDto
{
    public Guid QuestionId { get; set; }
    public List<Guid> SelectedAnswerOptionIds { get; set; } = [];
    public int? TimeSpentSeconds { get; set; }
    public DateTime? AnsweredAt { get; set; }
}

public sealed class OfflineSyncResultDto
{
    public required PracticeSessionResultDto SessionResult { get; init; }
    public required int VoidedQuestionCount { get; init; }
    public required bool ScoreAdjusted { get; init; }
}
