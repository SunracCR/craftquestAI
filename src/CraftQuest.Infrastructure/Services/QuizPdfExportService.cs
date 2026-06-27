using System.Text;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Quizzes;
using CraftQuest.Domain.Constants;
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
    private const string BrandName = "CraftQuestAI";
    private const string BrandWebsite = "www.CraftQuestAI.com";
    private const string BrandPrimaryColor = "#1A2F35";
    private const string BrandAccentColor = "#4ECDC4";

    public async Task<(byte[] Bytes, string FileName)> GenerateQuizPdfAsync(
        Guid userId,
        Guid quizId,
        string? languageCode,
        CancellationToken cancellationToken = default)
    {
        await EnsurePaidPlanAsync(userId, cancellationToken);

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

                page.Footer().Element(footer => ComposeBrandedFooter(
                    footer,
                    labels,
                    labels.QuestionsSection));
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

                page.Footer().Element(footer => ComposeBrandedFooter(
                    footer,
                    labels,
                    labels.AnswerSheetSection));
            });
        }).GeneratePdf();
    }

    private static void ComposeBrandedFooter(
        IContainer container,
        QuizPdfExportLabels labels,
        string? sectionLabel = null)
    {
        container.PaddingTop(4).Column(column =>
        {
            column.Item().Height(2).Background(BrandAccentColor);

            column.Item().PaddingTop(10).Row(row =>
            {
                row.RelativeItem(2).AlignLeft().Column(left =>
                {
                    left.Item().Text(BrandName)
                        .Bold()
                        .FontSize(10)
                        .FontColor(BrandPrimaryColor);
                    left.Item().PaddingTop(2).Text(labels.GeneratedBy)
                        .FontSize(7.5f)
                        .FontColor(Colors.Grey.Medium);
                });

                if (!string.IsNullOrEmpty(sectionLabel))
                {
                    row.RelativeItem().AlignCenter().AlignMiddle()
                        .PaddingVertical(2)
                        .PaddingHorizontal(10)
                        .Background(Colors.Grey.Lighten4)
                        .Text(sectionLabel)
                        .SemiBold()
                        .FontSize(7.5f)
                        .FontColor(BrandPrimaryColor);
                }
                else
                {
                    row.RelativeItem();
                }

                row.RelativeItem(2).AlignRight().Column(right =>
                {
                    right.Item().AlignRight().Text(BrandWebsite)
                        .SemiBold()
                        .FontSize(8.5f)
                        .FontColor(BrandAccentColor);
                    right.Item().PaddingTop(3).AlignRight()
                        .DefaultTextStyle(x => x.FontSize(7.5f).FontColor(Colors.Grey.Darken2))
                        .Text(text =>
                        {
                            text.Span($"{labels.Page} ");
                            text.CurrentPageNumber();
                            text.Span($" {labels.PageOf} ");
                            text.TotalPages();
                        });
                });
            });
        });
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

    private async Task EnsurePaidPlanAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var planCode = await dbContext.UserSubscriptions
            .AsNoTracking()
            .Where(s => s.UserId == userId && s.Status == SubscriptionStatuses.Active)
            .OrderByDescending(s => s.StartedAt)
            .Select(s => s.Plan.Code)
            .FirstOrDefaultAsync(cancellationToken);

        if (string.IsNullOrWhiteSpace(planCode)
            || planCode.Equals("free", StringComparison.OrdinalIgnoreCase))
        {
            throw new AppException(
                "PDF export requires a paid plan.",
                403,
                "QUIZ_PDF_PLAN_REQUIRED");
        }
    }

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
        string QuestionsSection,
        string AnswerSheetSection,
        string ImageOptionPlaceholder,
        string GeneratedBy,
        string Page,
        string PageOf)
    {
        public static QuizPdfExportLabels ForLanguage(string? languageCode) =>
            languageCode?.Trim().ToLowerInvariant() switch
            {
                "en" => new QuizPdfExportLabels(
                    "Question",
                    "Points",
                    "Answer key",
                    "Justification",
                    "Questions",
                    "Answer key",
                    "[Image option]",
                    "Generated by CraftQuestAI",
                    "Page",
                    "of"),
                "pt" => new QuizPdfExportLabels(
                    "Pergunta",
                    "Pontos",
                    "Gabarito",
                    "Justificativa",
                    "Perguntas",
                    "Gabarito",
                    "[Opcao com imagem]",
                    "Gerado por CraftQuestAI",
                    "Pag.",
                    "de"),
                _ => new QuizPdfExportLabels(
                    "Pregunta",
                    "Puntos",
                    "Hoja de respuestas",
                    "Justificacion",
                    "Preguntas",
                    "Respuestas",
                    "[Opcion con imagen]",
                    "Generado por CraftQuestAI",
                    "Pag.",
                    "de"),
            };
    }
}
