using CraftQuest.Application.Contracts;
using Microsoft.Extensions.Logging;

namespace CraftQuest.Infrastructure.Email;

public sealed class LoggingEmailSender(ILogger<LoggingEmailSender> logger) : IEmailSender
{
    public Task SendAsync(
        string toEmail,
        string subject,
        string plainTextBody,
        string? htmlBody = null,
        CancellationToken cancellationToken = default)
    {
        logger.LogWarning(
            "Email (dev log) To={ToEmail} Subject={Subject} HasHtml={HasHtml}\n{Body}",
            toEmail,
            subject,
            htmlBody is not null,
            plainTextBody);
        return Task.CompletedTask;
    }
}
