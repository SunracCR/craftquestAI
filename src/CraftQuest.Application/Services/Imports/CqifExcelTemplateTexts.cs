namespace CraftQuest.Application.Services.Imports;

internal sealed class CqifExcelTemplateTexts
{
    public required string SheetName { get; init; }
    public required string[] Headers { get; init; }
    public required IReadOnlyList<ExcelTemplateExampleRow> Examples { get; init; }
    public required string TypeValidationErrorTitle { get; init; }
    public required string TypeValidationErrorMessage { get; init; }

    public static string NormalizeLanguage(string? languageCode)
    {
        if (string.IsNullOrWhiteSpace(languageCode))
        {
            return "es";
        }

        var code = languageCode.Trim().ToLowerInvariant();
        return code switch
        {
            "en" => "en",
            "pt" => "pt",
            "es" => "es",
            _ => "es",
        };
    }

    public static CqifExcelTemplateTexts Get(string? languageCode) =>
        NormalizeLanguage(languageCode) switch
        {
            "en" => English,
            "pt" => Portuguese,
            _ => Spanish,
        };

    private static readonly CqifExcelTemplateTexts Spanish = new()
    {
        SheetName = "Preguntas",
        Headers =
        [
            "Pregunta",
            "Tipo",
            "Opción A",
            "Opción B",
            "Opción C",
            "Opción D",
            "Respuesta correcta",
            "Puntos",
            "Sección",
            "Justificación",
        ],
        TypeValidationErrorTitle = "Tipo no válido",
        TypeValidationErrorMessage =
            "Elige un valor de la lista: single_choice, multiple_choice, true_false, etc.",
        Examples =
        [
            new(
                "¿Cuál es la capital de Francia?",
                "single_choice",
                ["Londres", "París", "Berlín", "Madrid"],
                "B",
                1,
                "Geografía",
                "París es la capital y sede del gobierno de Francia."),
            new(
                "Seleccione lenguajes de programación",
                "multiple_choice",
                ["C#", "HTML", "Dart", "CSS"],
                "A|C",
                2,
                null),
            new(
                "La Tierra es plana",
                "true_false",
                ["Verdadero", "Falso", null, null],
                "B",
                1,
                null),
            new(
                "¿Qué animal aparece en la foto? (añade imagen en la app)",
                "image_choice",
                ["Gato", "Perro", "Conejo", "Pez"],
                "A",
                1,
                null),
            new(
                "Observa el diagrama e indica la respuesta correcta",
                "image_based_question",
                ["Opción A", "Opción B", "Opción C", "Opción D"],
                "B",
                2,
                "Visual"),
        ],
    };

    private static readonly CqifExcelTemplateTexts English = new()
    {
        SheetName = "Questions",
        Headers =
        [
            "Question",
            "Type",
            "Option A",
            "Option B",
            "Option C",
            "Option D",
            "Correct answer",
            "Points",
            "Section",
            "Justification",
        ],
        TypeValidationErrorTitle = "Invalid type",
        TypeValidationErrorMessage =
            "Choose a value from the list: single_choice, multiple_choice, true_false, etc.",
        Examples =
        [
            new(
                "What is the capital of France?",
                "single_choice",
                ["London", "Paris", "Berlin", "Madrid"],
                "B",
                1,
                "Geography",
                "Paris is the capital and seat of government of France."),
            new(
                "Select programming languages",
                "multiple_choice",
                ["C#", "HTML", "Dart", "CSS"],
                "A|C",
                2,
                null),
            new(
                "The Earth is flat",
                "true_false",
                ["True", "False", null, null],
                "B",
                1,
                null),
            new(
                "Which animal is in the photo? (add image in the app)",
                "image_choice",
                ["Cat", "Dog", "Rabbit", "Fish"],
                "A",
                1,
                null),
            new(
                "Look at the diagram and pick the correct answer",
                "image_based_question",
                ["Option A", "Option B", "Option C", "Option D"],
                "B",
                2,
                "Visual"),
        ],
    };

    private static readonly CqifExcelTemplateTexts Portuguese = new()
    {
        SheetName = "Perguntas",
        Headers =
        [
            "Pergunta",
            "Tipo",
            "Opção A",
            "Opção B",
            "Opção C",
            "Opção D",
            "Resposta correta",
            "Pontos",
            "Seção",
            "Justificação",
        ],
        TypeValidationErrorTitle = "Tipo inválido",
        TypeValidationErrorMessage =
            "Escolha um valor da lista: single_choice, multiple_choice, true_false, etc.",
        Examples =
        [
            new(
                "Qual é a capital da França?",
                "single_choice",
                ["Londres", "Paris", "Berlim", "Madrid"],
                "B",
                1,
                "Geografia",
                "Paris é a capital e sede do governo da França."),
            new(
                "Selecione linguagens de programação",
                "multiple_choice",
                ["C#", "HTML", "Dart", "CSS"],
                "A|C",
                2,
                null),
            new(
                "A Terra é plana",
                "true_false",
                ["Verdadeiro", "Falso", null, null],
                "B",
                1,
                null),
            new(
                "Qual animal aparece na foto? (adicione imagem no app)",
                "image_choice",
                ["Gato", "Cachorro", "Coelho", "Peixe"],
                "A",
                1,
                null),
            new(
                "Observe o diagrama e indique a resposta correta",
                "image_based_question",
                ["Opção A", "Opção B", "Opção C", "Opção D"],
                "B",
                2,
                "Visual"),
        ],
    };
}

internal sealed record ExcelTemplateExampleRow(
    string Question,
    string Type,
    string?[] Options,
    string Correct,
    decimal Points,
    string? Section,
    string? Justification = null);
