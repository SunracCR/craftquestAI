using System.Text.RegularExpressions;
using CraftQuest.Application.Contracts;

namespace CraftQuest.UnitTests.Auth;

public sealed class CapturingEmailSender : IEmailSender
{
    public string? LastToEmail { get; private set; }

    public string? LastSubject { get; private set; }

    public string? LastPlainTextBody { get; private set; }

    public string? LastHtmlBody { get; private set; }

    public Task SendAsync(
        string toEmail,
        string subject,
        string plainTextBody,
        string? htmlBody = null,
        CancellationToken cancellationToken = default)
    {
        LastToEmail = toEmail;
        LastSubject = subject;
        LastPlainTextBody = plainTextBody;
        LastHtmlBody = htmlBody;
        return Task.CompletedTask;
    }

    public void Reset()
    {
        LastToEmail = null;
        LastSubject = null;
        LastPlainTextBody = null;
        LastHtmlBody = null;
    }

    public string? ExtractTokenFromLastEmail()
    {
        var source = LastPlainTextBody ?? LastHtmlBody;
        if (string.IsNullOrWhiteSpace(source))
        {
            return null;
        }

        var match = Regex.Match(
            source,
            @"(?:verify-email|reset-password|confirm-password-change)/([A-Za-z0-9._~-]+)",
            RegexOptions.CultureInvariant);

        return match.Success ? Uri.UnescapeDataString(match.Groups[1].Value) : null;
    }
}
