namespace CraftQuest.Application.Models.Auth;

/// <summary>Configuración OAuth expuesta al cliente (sin secretos).</summary>
public sealed class OAuthPublicConfigDto
{
    public string? GoogleWebClientId { get; init; }
    public bool IsGoogleConfigured { get; init; }
    public bool IsAppleConfigured { get; init; }

    /// <summary>Services ID para Sign in with Apple en web.</summary>
    public string? AppleServicesId { get; init; }

    /// <summary>Return URL (debe coincidir con Apple Developer → Service ID).</summary>
    public string? AppleWebRedirectUri { get; init; }

    public bool IsAppleWebConfigured { get; init; }
}
