namespace CraftQuest.Application.Options;

public class ExternalAuthOptions
{
    public const string SectionName = "ExternalAuth";

    public GoogleAuthOptions Google { get; set; } = new();
    public AppleAuthOptions Apple { get; set; } = new();
}

public class GoogleAuthOptions
{
    /// <summary>OAuth 2.0 Web client ID (audience del id_token para validación en servidor).</summary>
    public string WebClientId { get; set; } = string.Empty;

    /// <summary>Client IDs adicionales (Android/iOS) aceptados como audience.</summary>
    public List<string> AdditionalClientIds { get; set; } = [];
}

public class AppleAuthOptions
{
    /// <summary>Bundle ID de la app iOS (audience del identity token nativo).</summary>
    public string BundleId { get; set; } = "com.craftquestai.craftquestaiApp";

    /// <summary>Services ID (Sign in with Apple en web/Android), si aplica.</summary>
    public string? ServicesId { get; set; }

    /// <summary>Return URL registrada en Apple (web), p. ej. https://app.craftquestai.com (sin barra final; usePopup).</summary>
    public string? WebRedirectUri { get; set; }
}
