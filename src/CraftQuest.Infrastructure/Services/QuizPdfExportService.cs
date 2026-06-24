using System.Text;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Quizzes;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace CraftQuest.Infrastructure.Services;

public class QuizPdfExportService(
    IQuizService quizService,
    CraftQuestDbContext dbContext) : IQuizPdfExportService
{
    private const string QuestionImageStableKey = "QUESTION_IMAGE";

    public async Task<(byte[] Bytes, string FileName)> GenerateQuizPdfAsync(
        Guid userId,
        Guid quizId,
        string? languageCode,
        CancellationToken cancellationToken = default)
    {
        var questions = await quizService.GetQuestionsForAuthorAsync(
            userId,
            quizId,
            cancellationToken);

        if (questions.Count == 0)
        {
            throw new AppException(
                "This quiz has no questions to export.",
                400,
                "QUIZ_PDF_EMPTY");
        }

        var quiz = await dbContext.Quizzes
            .AsNoTracking()
            .FirstOrDefaultAsync(q => q.QuizId == quizId, cancellationToken)
            ?? throw new AppException("Quiz not found.", 404);

        var labels = QuizPdfExportLabels.ForLanguage(languageCode);
        var fileName = $"{SanitizeFileName(quiz.Title)}.pdf";
        var bytes = BuildPdf(quiz.Title, quiz.Description, questions, labels);

        return (bytes, fileName);
    }

    private static byte[] BuildPdf(
        string title,
        string? description,
        IReadOnlyList<QuestionDto> questions,
        QuizPdfExportLabels labels)
    {
        return Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(40);
                page.DefaultTextStyle(x => x.FontSize(11));

                page.Header().Column(column =>
                {
                    column.Item().Text(title).Bold().FontSize(18);
                    if (!string.IsNullOrWhiteSpace(description))
                    {
                        column.Item().PaddingTop(6).Text(description!).FontSize(11);
                    }
                    column.Item().PaddingTop(12).LineHorizontal(1);
                });

                page.Content().PaddingTop(16).Column(column =>
                {
                    for (var index = 0; index < questions.Count; index++)
                    {
                        var question = questions[index];
                        var number = index + 1;
                        var visibleOptions = GetVisibleOptions(question);

                        column.Item().PaddingBottom(14).Column(block =>
                        {
                            block.Item().Text($"{labels.Question} {number}").Bold().FontSize(12);
                            block.Item().PaddingTop(4).Text(question.Text);
                            block.Item().PaddingTop(2).Text($"{labels.Points}: {FormatPoints(question.Points)}")
                                .FontSize(9)
                                .FontColor(Colors.Grey.Darken2);

                            foreach (var option in visibleOptions)
                            {
                                var optionText = string.IsNullOrWhiteSpace(option.Text)
                                    ? labels.ImageOptionPlaceholder
                                    : option.Text!.Trim();
                                block.Item().PaddingTop(4).Text($"{option.StableKey}. {optionText}");
                            }
                        });
                    }
                });

                page.Footer().AlignCenter().Text(text =>
                {
                    text.Span(labels.QuestionsSectionFooter);
                    text.CurrentPageNumber();
                    text.Span(" / ");
                    text.TotalPages();
                });
            });

            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(40);
                page.DefaultTextStyle(x => x.FontSize(11));

                page.Header().Column(column =>
                {
                    column.Item().Text(labels.AnswerSheetTitle).Bold().FontSize(18);
                    column.Item().PaddingTop(6).Text(title).FontSize(12);
                    column.Item().PaddingTop(12).LineHorizontal(1);
                });

                page.Content().PaddingTop(16).Column(column =>
                {
                    for (var index = 0; index < questions.Count; index++)
                    {
                        var question = questions[index];
                        var number = index + 1;
                        var correctKeys = ResolveCorrectKeys(question);

                        column.Item().PaddingBottom(12).Column(block =>
                        {
                            block.Item().Text($"{number}. {correctKeys}").Bold();
                            var justification = question.Justification?.Text?.Trim();
                            if (!string.IsNullOrWhiteSpace(justification))
                            {
                                block.Item().PaddingTop(4).Text($"{labels.Justification}:").SemiBold();
                                block.Item().PaddingTop(2).Text(justification!);
                            }
                        });
                    }
                });

                page.Footer().AlignCenter().Text(text =>
                {
                    text.CurrentPageNumber();
                    text.Span(" / ");
                    text.TotalPages();
                });
            });
        }).GeneratePdf();
    }

    private static IReadOnlyList<AnswerOptionDto> GetVisibleOptions(QuestionDto question) =>
        question.AnswerOptions
            .Where(o => !string.Equals(o.StableKey, QuestionImageStableKey, StringComparison.OrdinalIgnoreCase))
            .ToList();

    private static string ResolveCorrectKeys(QuestionDto question)
    {
        var correctIds = question.CorrectAnswerOptionIds.ToHashSet();
        var keys = question.AnswerOptions
            .Where(o => correctIds.Contains(o.AnswerOptionId))
            .Select(o => o.StableKey)
            .ToList();

        return keys.Count == 0 ? "-" : string.Join(", ", keys);
    }

    private static string FormatPoints(decimal points) =>
        points % 1 == 0 ? ((int)points).ToString() : points.ToString("0.##");

    private static string SanitizeFileName(string title)
    {
        var invalid = Path.GetInvalidFileNameChars();
        var builder = new StringBuilder(title.Length);
        foreach (var ch in title.Trim())
        {
            builder.Append(invalid.Contains(ch) ? '_' : ch);
        }

        var sanitized = builder.ToString().Trim();
        return string.IsNullOrWhiteSpace(sanitized) ? "quiz" : sanitized[..Math.Min(sanitized.Length, 120)];
    }

    private sealed record QuizPdfExportLabels(
        string Question,
        string Points,
        string AnswerSheetTitle,
        string Justification,
        string QuestionsSectionFooter,
        string ImageOptionPlaceholder)
    {
        public static QuizPdfExportLabels ForLanguage(string? languageCode) =>
            languageCode?.Trim().ToLowerInvariant() switch
            {
                "en" => new QuizPdfExportLabels(
                    "Question",
                    "Points",
                    "Answer key",
                    "Justification",
                    "Questions — page ",
                    "[Image option]"),
                "pt" => new QuizPdfExportLabels(
                    "Pergunta",
                    "Pontos",
                    "Gabarito",
                    "Justificativa",
                    "Perguntas — pagina ",
                    "[Opcao com imagem]"),
                _ => new QuizPdfExportLabels(
                    "Pregunta",
                    "Puntos",
                    "Hoja de respuestas",
                    "Justificacion",
                    "Preguntas — pagina ",
                    "[Opcion con imagen]"),
            };
    }
}
