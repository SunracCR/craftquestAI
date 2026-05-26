namespace CraftQuest.Application.Contracts;

public sealed class ExtractedPage
{
    public required int PageNumber { get; init; }
    public string Text { get; init; } = string.Empty;
    public int WordCount { get; init; }
    public bool HasEmbeddedImages { get; init; }
    public string ExtractionQuality { get; init; } = "good";
}

public sealed class ExtractedSection
{
    public required string Title { get; init; }
    public required int PageFrom { get; init; }
    public required int PageTo { get; init; }
    public int SortOrder { get; init; }
}

public sealed class DocumentExtractionResult
{
    public required IReadOnlyList<ExtractedPage> Pages { get; init; }
    public required IReadOnlyList<ExtractedSection> Sections { get; init; }
    public bool NeedsOcr { get; init; }
}

public interface IPageTextExtractor
{
    string FileType { get; }

    Task<DocumentExtractionResult> ExtractAsync(
        Stream content,
        CancellationToken cancellationToken = default);
}
