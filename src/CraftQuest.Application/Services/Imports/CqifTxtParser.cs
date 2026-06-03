using System.Text.RegularExpressions;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Imports;

namespace CraftQuest.Application.Services.Imports;

public static partial class CqifTxtParser
{
    private static readonly Regex AnswerLineRegex = AnswerLinePattern();

    public static CqifDocument Parse(string rawText)
    {
        if (string.IsNullOrWhiteSpace(rawText))
        {
            throw new AppException("TXT content is empty.", 400);
        }

        var quizMeta = new CqifQuizMetadata();
        var questions = new List<CqifQuestion>();
        Dictionary<string, string>? currentQuestion = null;
        var section = string.Empty;
        var order = 0;

        foreach (var rawLine in rawText.Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries))
        {
            var line = rawLine.Trim();
            if (line.Length == 0 || line.StartsWith('#'))
            {
                continue;
            }

            if (line.Equals("[QUIZ]", StringComparison.OrdinalIgnoreCase))
            {
                FlushQuestion();
                section = "quiz";
                continue;
            }

            if (line.Equals("[QUESTION]", StringComparison.OrdinalIgnoreCase))
            {
                FlushQuestion();
                section = "question";
                currentQuestion = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                continue;
            }

            if (section == "quiz")
            {
                ApplyKeyValue(line, quizMeta);
                continue;
            }

            if (section != "question" || currentQuestion is null)
            {
                continue;
            }

            var answerMatch = AnswerLineRegex.Match(line);
            if (answerMatch.Success)
            {
                var key = answerMatch.Groups[1].Value.Trim();
                var text = answerMatch.Groups[2].Value.Trim();
                currentQuestion[$"answer:{key}"] = text;
                continue;
            }

            var equalsIndex = line.IndexOf('=');
            if (equalsIndex <= 0)
            {
                continue;
            }

            var field = line[..equalsIndex].Trim();
            var value = line[(equalsIndex + 1)..].Trim();
            currentQuestion[field] = value;
        }

        FlushQuestion();
        return new CqifDocument
        {
            CqifVersion = "2.0",
            Quiz = quizMeta,
            Questions = questions,
        };

        void FlushQuestion()
        {
            if (currentQuestion is null || currentQuestion.Count == 0)
            {
                currentQuestion = null;
                return;
            }

            order++;
            questions.Add(MapQuestion(currentQuestion, order, quizMeta));
            currentQuestion = null;
        }
    }

    private static void ApplyKeyValue(string line, CqifQuizMetadata quiz)
    {
        var equalsIndex = line.IndexOf('=');
        if (equalsIndex <= 0)
        {
            return;
        }

        var key = line[..equalsIndex].Trim().ToLowerInvariant();
        var value = line[(equalsIndex + 1)..].Trim();

        switch (key)
        {
            case "title":
                quiz.Title = value;
                break;
            case "description":
                quiz.Description = value;
                break;
            case "default_points":
                if (decimal.TryParse(value, out var points))
                {
                    quiz.DefaultPoints = points;
                }

                break;
            case "default_randomize_answers":
                quiz.DefaultRandomizeAnswerOptions = ParseBool(value);
                break;
        }
    }

    private static CqifQuestion MapQuestion(
        Dictionary<string, string> fields,
        int fallbackOrder,
        CqifQuizMetadata quizDefaults)
    {
        var answerOptions = fields
            .Where(kv => kv.Key.StartsWith("answer:", StringComparison.OrdinalIgnoreCase))
            .Select(kv => new CqifAnswerOption
            {
                Key = kv.Key["answer:".Length..],
                Text = kv.Value,
            })
            .ToList();

        var correctKeys = fields.TryGetValue("correct", out var correctRaw)
            ? correctRaw.Split('|', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .ToList()
            : [];

        fields.TryGetValue("type", out var type);
        fields.TryGetValue("text", out var text);
        fields.TryGetValue("section", out var section);
        fields.TryGetValue("external_id", out var externalId);
        fields.TryGetValue("difficulty", out var difficulty);
        fields.TryGetValue("scoring_policy", out var scoringPolicy);
        fields.TryGetValue("justification", out var justificationText);

        decimal? points = null;
        if (fields.TryGetValue("points", out var pointsRaw) &&
            decimal.TryParse(pointsRaw, out var parsedPoints))
        {
            points = parsedPoints;
        }
        else
        {
            points = quizDefaults.DefaultPoints;
        }

        bool? randomize = null;
        if (fields.TryGetValue("randomize_answers", out var randomizeRaw))
        {
            randomize = ParseBool(randomizeRaw);
        }
        else
        {
            randomize = quizDefaults.DefaultRandomizeAnswerOptions;
        }

        return new CqifQuestion
        {
            ExternalId = externalId,
            Section = section,
            Order = fallbackOrder,
            Type = type ?? "single_choice",
            Text = text ?? string.Empty,
            Points = points,
            Difficulty = difficulty,
            RandomizeAnswerOptions = randomize,
            ScoringPolicy = scoringPolicy ?? "strict",
            AnswerOptions = answerOptions,
            CorrectAnswerKeys = correctKeys,
            Justification = string.IsNullOrWhiteSpace(justificationText)
                ? null
                : new CqifJustification
                {
                    Text = justificationText,
                    Visibility = "never",
                    Status = "needs_review",
                },
        };
    }

    private static bool ParseBool(string value) =>
        value.Equals("true", StringComparison.OrdinalIgnoreCase) ||
        value.Equals("1", StringComparison.OrdinalIgnoreCase) ||
        value.Equals("yes", StringComparison.OrdinalIgnoreCase);

    [GeneratedRegex(@"^answer\[([^\]]+)\]=(.*)$", RegexOptions.IgnoreCase)]
    private static partial Regex AnswerLinePattern();
}
