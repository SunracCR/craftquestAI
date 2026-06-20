using System.Text;
using CraftQuest.Application.Contracts;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;

namespace CraftQuest.Infrastructure.StudyMaterials;

public class DocxPageTextExtractor : IPageTextExtractor
{
    public string FileType => "docx";

    public async Task<DocumentExtractionResult> ExtractAsync(
        Stream content,
        CancellationToken cancellationToken = default)
    {
        var seekable = await StudyMaterialStreamHelper.OpenSeekableCopyAsync(
            content,
            cancellationToken);
        var ownsCopy = !ReferenceEquals(seekable, content);

        try
        {
            return ExtractFromSeekableStream(seekable, cancellationToken);
        }
        finally
        {
            if (ownsCopy)
            {
                await seekable.DisposeAsync();
            }
        }
    }

    private static DocumentExtractionResult ExtractFromSeekableStream(
        Stream content,
        CancellationToken cancellationToken)
    {
        using var document = WordprocessingDocument.Open(content, false);
        var body = document.MainDocumentPart?.Document.Body;
        if (body is null)
        {
            return new DocumentExtractionResult
            {
                Pages = [],
                Sections = [],
                NeedsOcr = true,
            };
        }

        var pages = new List<ExtractedPage>();
        var sections = new List<ExtractedSection>();
        var currentPageText = new StringBuilder();
        var pageNumber = 1;
        var sectionSort = 0;

        foreach (var element in body.Elements())
        {
            cancellationToken.ThrowIfCancellationRequested();

            if (element is Paragraph paragraph)
            {
                var text = paragraph.InnerText?.Trim() ?? string.Empty;
                if (text.Length == 0)
                {
                    continue;
                }

                var styleId = paragraph.ParagraphProperties?.ParagraphStyleId?.Val?.Value;
                if (IsHeadingStyle(styleId) || LooksLikeHeading(text))
                {
                    FlushPage();
                    sections.Add(new ExtractedSection
                    {
                        Title = text,
                        PageFrom = pageNumber,
                        PageTo = pageNumber,
                        SortOrder = sectionSort++,
                    });
                }

                if (paragraph.ParagraphProperties?.PageBreakBefore?.Val?.Value == true
                    || text.Contains('\f'))
                {
                    FlushPage();
                }

                currentPageText.AppendLine(text);
            }
        }

        FlushPage();

        if (sections.Count == 0)
        {
            sections.AddRange(StudyMaterialOutlineHelper.BuildHeuristicSections(pages));
        }

        return new DocumentExtractionResult
        {
            Pages = pages,
            Sections = sections.Take(40).ToList(),
            NeedsOcr = StudyMaterialOutlineHelper.DetectNeedsOcr(pages),
        };

        void FlushPage()
        {
            var text = currentPageText.ToString().Trim();
            currentPageText.Clear();
            if (text.Length == 0 && pages.Count > 0)
            {
                pageNumber++;
                return;
            }

            if (text.Length == 0)
            {
                return;
            }

            var wordCount = text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries).Length;
            pages.Add(new ExtractedPage
            {
                PageNumber = pageNumber,
                Text = text,
                WordCount = wordCount,
                ExtractionQuality = ClassifyQuality(wordCount),
            });
            pageNumber++;
        }
    }

    private static bool IsHeadingStyle(string? styleId) =>
        styleId is not null
        && (styleId.Contains("Heading", StringComparison.OrdinalIgnoreCase)
            || styleId.StartsWith('1') || styleId.StartsWith('2'));

    private static bool LooksLikeHeading(string text) =>
        text.Length is >= 4 and <= 120
        && char.IsUpper(text[0])
        && !text.EndsWith('.');

    private static string ClassifyQuality(int wordCount) => wordCount switch
    {
        0 => "empty",
        < 4 => "low",
        _ => "good",
    };
}
