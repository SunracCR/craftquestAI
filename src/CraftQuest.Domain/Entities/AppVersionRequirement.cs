namespace CraftQuest.Domain.Entities;

/// <summary>
/// Requisito de versión mínima por plataforma para forzar actualización de la app móvil.
/// Una fila por <see cref="Platform"/> (p. ej. "android", "ios").
/// </summary>
public class AppVersionRequirement
{
    public int AppVersionRequirementId { get; set; }

    public string Platform { get; set; } = string.Empty;

    /// <summary>Versión mínima permitida (SemVer "MAJOR.MINOR.PATCH"). Por debajo, la app bloquea.</summary>
    public string MinSupportedVersion { get; set; } = string.Empty;

    /// <summary>Última versión publicada (informativa; puede usarse a futuro para avisos no bloqueantes).</summary>
    public string? LatestVersion { get; set; }

    public string UpdateUrl { get; set; } = string.Empty;

    /// <summary>Mensaje opcional mostrado en la pantalla de bloqueo (fallback a texto localizado si es null).</summary>
    public string? Message { get; set; }

    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
}
