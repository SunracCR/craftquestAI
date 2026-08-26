namespace CraftQuest.Application.Options;

public class TurnstileOptions
{
    public const string SectionName = "Captcha:Turnstile";

    public string SiteKey { get; set; } = string.Empty;

    public string SecretKey { get; set; } = string.Empty;

    /// <summary>
    /// When true, web clients (X-Client-Platform: web) must pass a valid captcha token
    /// on login and register.
    /// </summary>
    public bool Enforce { get; set; }
}
