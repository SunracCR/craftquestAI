using CraftQuest.Application.Contracts;
using UglyToad.PdfPig;

namespace CraftQuest.Infrastructure.StudyMaterials;

public class PdfPageTextExtractor : IPageTextExtractor
{
    public string FileType => "pdf";

    public Task<DocumentExtractionResult> ExtractAsync(
        Stream content,
        CancellationToken cancellationToken = default)
    {
        var pages = new List<ExtractedPage>();
        using var document = PdfDocument.Open(content);

        foreach (var page in document.GetPages())
        {
            cancellationToken.ThrowIfCancellationRequested();
            var text = PdfTextExtractionHelper.ExtractPageText(page);
            var wordCount = StudyMaterialOutlineHelper.CountWords(text);
            var quality = ClassifyQuality(wordCount);

            pages.Add(new ExtractedPage
            {
                PageNumber = page.Number,
                Text = text,
                WordCount = wordCount,
                HasEmbeddedImages = page.GetImages().Any(),
                ExtractionQuality = quality,
            });
        }

        var sections = StudyMaterialOutlineHelper.BuildHeuristicSections(pages);
        var needsOcr = StudyMaterialOutlineHelper.DetectNeedsOcr(pages);

        return Task.FromResult(new DocumentExtractionResult
        {
            Pages = pages,
            Sections = sections,
            NeedsOcr = needsOcr,
        });
    }

    private static string ClassifyQuality(int wordCount) => wordCount switch
    {
        0 => "empty",
        < 4 => "low",
        _ => "good",
    };
}
