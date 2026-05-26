using CraftQuest.Application.Services.StudyMaterials;
using CraftQuest.Domain.Entities;

namespace CraftQuest.UnitTests.StudyMaterials;

public sealed class StudyMaterialLanguageResolverTests
{
    [Fact]
    public void DetectFromText_EnglishSample_ReturnsEn()
    {
        const string text =
            "The experiment shows that software engineering methods can improve study data quality. "
            + "This chapter section describes the method used in the analysis.";

        var result = StudyMaterialLanguageResolver.DetectFromText(text);

        Assert.Equal("en", result);
    }

    [Fact]
    public void DetectFromText_SpanishSample_ReturnsEs()
    {
        const string text =
            "El capítulo describe el método de estudio y los datos del experimento. "
            + "Esta sección explica la ingeniería de software para la evaluación.";

        var result = StudyMaterialLanguageResolver.DetectFromText(text);

        Assert.Equal("es", result);
    }

    [Fact]
    public void Resolve_UsesStoredLanguageCode_WhenPresent()
    {
        var material = new StudyMaterial
        {
            LanguageCode = "en",
            OriginalText = "El capítulo en español no debe cambiar el idioma guardado.",
        };

        var result = StudyMaterialLanguageResolver.Resolve(material, 1, 1);

        Assert.Equal("en", result);
    }
}
