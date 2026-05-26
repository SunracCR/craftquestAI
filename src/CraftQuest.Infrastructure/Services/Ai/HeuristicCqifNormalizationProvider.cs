using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Imports;
using CraftQuest.Application.Services.Imports;

namespace CraftQuest.Infrastructure.Services.Ai;

public class HeuristicCqifNormalizationProvider : ICqifNormalizationProvider
{
    public string ProviderName => "heuristic";

    public Task<CqifDocument> NormalizeAsync(
        string rawText,
        string language,
        string defaultQuestionType,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();

        CqifDocument document;
        try
        {
            document = CqifJsonParser.Parse(rawText);
        }
        catch (AppException)
        {
            try
            {
                document = CqifTxtParser.Parse(rawText);
            }
            catch (AppException)
            {
                document = BuildSingleQuestionDocument(rawText, defaultQuestionType);
            }
        }

        if (document.Questions.Count == 0)
        {
            document = BuildSingleQuestionDocument(rawText, defaultQuestionType);
        }

        document.CqifVersion = "2.0";
        if (string.IsNullOrWhiteSpace(document.Quiz.Title))
        {
            document.Quiz.Title = language switch
            {
                "en" => "Imported quiz",
                "pt" => "Questionario importado",
                _ => "Cuestionario importado",
            };
        }

        return Task.FromResult(document);
    }

    private static CqifDocument BuildSingleQuestionDocument(string rawText, string defaultQuestionType)
    {
        var text = rawText.Trim();
        if (text.Length > 4000)
        {
            text = text[..4000];
        }

        var type = defaultQuestionType is "single_choice" or "multiple_choice" or "true_false"
            ? defaultQuestionType
            : "single_choice";

        if (type == "true_false")
        {
            return new CqifDocument
            {
                CqifVersion = "2.0",
                Quiz = new CqifQuizMetadata { Title = "Cuestionario importado" },
                Questions =
                [
                    new CqifQuestion
                    {
                        Type = "true_false",
                        Text = text,
                        AnswerOptions =
                        [
                            new CqifAnswerOption { Key = "TRUE", Text = "Verdadero" },
                            new CqifAnswerOption { Key = "FALSE", Text = "Falso" },
                        ],
                        CorrectAnswerKeys = ["TRUE"],
                    },
                ],
            };
        }

        return new CqifDocument
        {
            CqifVersion = "2.0",
            Quiz = new CqifQuizMetadata { Title = "Cuestionario importado" },
            Questions =
            [
                new CqifQuestion
                {
                    Type = type,
                    Text = text,
                    AnswerOptions =
                    [
                        new CqifAnswerOption { Key = "A", Text = "Opcion A" },
                        new CqifAnswerOption { Key = "B", Text = "Opcion B" },
                        new CqifAnswerOption { Key = "C", Text = "Opcion C" },
                        new CqifAnswerOption { Key = "D", Text = "Opcion D" },
                    ],
                    CorrectAnswerKeys = ["A"],
                    Justification = new CqifJustification
                    {
                        Text = "Revisa y ajusta las opciones y la respuesta correcta.",
                        Status = "needs_review",
                    },
                },
            ],
        };
    }
}
