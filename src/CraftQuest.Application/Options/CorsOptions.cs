namespace CraftQuest.Application.Options;

public class CorsOptions
{
    public const string SectionName = "Cors";

    /// <summary>
    /// Orígenes permitidos en entorno Production (p. ej. la app Flutter web).
    /// En Development se ignora y se permite cualquier origen.
    /// </summary>
    public string[] AllowedOrigins { get; set; } = [];
}
