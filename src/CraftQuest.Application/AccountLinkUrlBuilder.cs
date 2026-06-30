using CraftQuest.Application.Options;

namespace CraftQuest.Application;

public static class AccountLinkUrlBuilder
{
    public const string VerifyEmail = "verify-email";
    public const string ResetPassword = "reset-password";
    public const string ConfirmPasswordChange = "confirm-password-change";
    public const string ParentalConsent = "parental-consent";

    public static string BuildLandingUrl(JoinLinkOptions options, string action, string rawToken)
    {
        var baseUrl = options.LinkBaseUrl.TrimEnd('/');
        return $"{baseUrl}/{action}/{Uri.EscapeDataString(rawToken)}";
    }

    public static string BuildWebUrl(JoinLinkOptions options, string action, string rawToken)
    {
        var baseUrl = options.WebAppUrl.TrimEnd('/');
        return $"{baseUrl}/{action}?token={Uri.EscapeDataString(rawToken)}";
    }

    public static string BuildDeepLink(string action, string rawToken) =>
        $"craftquest://{action}/{Uri.EscapeDataString(rawToken)}";
}
