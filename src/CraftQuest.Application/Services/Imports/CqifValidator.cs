using CraftQuest.Application.Models.Imports;

namespace CraftQuest.Application.Services.Imports;

public static class CqifValidator
{
    private static readonly HashSet<string> SupportedTypes =
    [
        "single_choice",
        "multiple_choice",
        "true_false",
        "image_choice",
        "image_based_question",
    ];

    private static readonly HashSet<string> SingleCorrectTypes =
    ["single_choice", "true_false", "image_choice", "image_based_question"];

    public static List<CqifValidationIssue> ValidateDocument(CqifDocument document)
    {
        var issues = new List<CqifValidationIssue>();

        if (!string.Equals(document.CqifVersion, "2.0", StringComparison.Ordinal))
        {
            issues.Add(new CqifValidationIssue
            {
                FieldName = "cqifVersion",
                ErrorCode = "CQIF_VERSION_UNSUPPORTED",
                Message = "Only CQIF version 2.0 is supported.",
            });
        }

        if (document.Questions.Count == 0)
        {
            issues.Add(new CqifValidationIssue
            {
                ErrorCode = "NO_QUESTIONS",
                Message = "At least one question is required.",
            });
            return issues;
        }

        for (var i = 0; i < document.Questions.Count; i++)
        {
            issues.AddRange(ValidateQuestion(document.Questions[i], i + 1));
        }

        return issues;
    }

    public static List<CqifValidationIssue> ValidateQuestion(CqifQuestion question, int rowNumber)
    {
        var issues = new List<CqifValidationIssue>();

        if (string.IsNullOrWhiteSpace(question.Text))
        {
            issues.Add(Issue(rowNumber, "text", "QUESTION_TEXT_REQUIRED", "Question text is required."));
        }

        if (!SupportedTypes.Contains(question.Type))
        {
            issues.Add(Issue(
                rowNumber,
                "type",
                "QUESTION_TYPE_INVALID",
                $"Question type '{question.Type}' is not supported."));
        }

        if (question.AnswerOptions.Count < 2)
        {
            issues.Add(Issue(
                rowNumber,
                "answerOptions",
                "ANSWER_OPTIONS_MIN",
                "At least two answer options are required."));
        }

        var keys = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var option in question.AnswerOptions)
        {
            if (string.IsNullOrWhiteSpace(option.Key))
            {
                issues.Add(Issue(rowNumber, "answerOptions.key", "ANSWER_KEY_REQUIRED", "Answer option key is required."));
                continue;
            }

            var normalized = option.Key.Trim().ToUpperInvariant();
            if (!keys.Add(normalized))
            {
                issues.Add(Issue(
                    rowNumber,
                    "answerOptions.key",
                    "ANSWER_KEY_DUPLICATE",
                    $"Duplicate answer key '{option.Key}'."));
            }
        }

        if (question.CorrectAnswerKeys.Count == 0)
        {
            issues.Add(Issue(
                rowNumber,
                "correctAnswerKeys",
                "CORRECT_KEYS_REQUIRED",
                "At least one correctAnswerKey is required."));
        }

        foreach (var correctKey in question.CorrectAnswerKeys)
        {
            if (!keys.Contains(correctKey.Trim().ToUpperInvariant()))
            {
                issues.Add(Issue(
                    rowNumber,
                    "correctAnswerKeys",
                    "CORRECT_KEY_UNKNOWN",
                    $"Correct answer key '{correctKey}' does not match any answer option key."));
            }
        }

        if (SingleCorrectTypes.Contains(question.Type) && question.CorrectAnswerKeys.Count != 1)
        {
            issues.Add(Issue(
                rowNumber,
                "correctAnswerKeys",
                "CORRECT_KEYS_COUNT",
                "This question type allows exactly one correct answer key."));
        }

        if (question.Type == "multiple_choice" && question.CorrectAnswerKeys.Count < 1)
        {
            issues.Add(Issue(
                rowNumber,
                "correctAnswerKeys",
                "CORRECT_KEYS_REQUIRED",
                "Multiple choice questions require at least one correct answer key."));
        }

        if (question.Type is "image_choice" or "image_based_question")
        {
            issues.Add(new CqifValidationIssue
            {
                RowNumber = rowNumber,
                FieldName = "media",
                ErrorCode = "IMAGE_MEDIA_PENDING",
                Message =
                    "Images are not imported from this file. You can attach them later in the app.",
                Severity = "warning",
            });
        }

        return issues;
    }

    private static CqifValidationIssue Issue(int rowNumber, string field, string code, string message) =>
        new()
        {
            RowNumber = rowNumber,
            FieldName = field,
            ErrorCode = code,
            Message = message,
            Severity = "error",
        };
}
