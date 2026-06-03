namespace CraftQuest.Application.Options;

public class PasswordResetOptions
{
    public const string SectionName = "PasswordReset";

    public int TokenLifetimeMinutes { get; set; } = 60;

    /// <summary>Secret used when hashing reset tokens at rest.</summary>
    public string Pepper { get; set; } = string.Empty;

    /// <summary>Base URL for the reset screen (Flutter web/app), e.g. https://app.example.com/reset-password</summary>
    public string AppResetUrlBase { get; set; } = "http://localhost:8080/reset-password";

    public string FromEmail { get; set; } = "noreply@craftquest.app";

    public string FromDisplayName { get; set; } = "CraftQuest";

    public bool LogEmailsInDevelopment { get; set; } = true;
}
