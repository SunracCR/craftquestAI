using CraftQuest.Infrastructure.Services.Ai;

namespace CraftQuest.UnitTests;

public class HeuristicCqifNormalizationProviderTests
{
    private readonly HeuristicCqifNormalizationProvider _provider = new();

    [Fact]
    public async Task NormalizeAsync_ParsesTxtFormat()
    {
        const string txt = """
            [QUESTION]
            type=single_choice
            text=What is 2+2?
            answer[A]=3
            answer[B]=4
            answer[C]=5
            correct=B
            """;

        var document = await _provider.NormalizeAsync(txt, "es", "single_choice");

        Assert.Single(document.Questions);
        Assert.Equal("What is 2+2?", document.Questions[0].Text);
        Assert.Contains(document.Questions[0].CorrectAnswerKeys, k => k == "B");
    }

    [Fact]
    public async Task NormalizeAsync_FallbackCreatesSingleQuestion()
    {
        var document = await _provider.NormalizeAsync(
            "Pregunta libre sin formato",
            "es",
            "single_choice");

        Assert.Single(document.Questions);
        Assert.Equal("Pregunta libre sin formato", document.Questions[0].Text);
    }
}
