using CraftQuest.Application.Contracts;
using Microsoft.Extensions.Logging;

namespace CraftQuest.Infrastructure.Email;

public sealed class LoggingEmailSender(ILogger<LoggingEmailSender> logger) : IEmailSender
{
    public Task SendAsync(
        string toEmail,
        string subject,
        string plainTextBody,
        CancellationToken cancellationToken = default)
    {
        logger.LogWarning(
            "Email (dev log) To={ToEmail} Subject={Subject}\n{Body}",
            toEmail,
            subject,
            plainTextBody);
        return Task.CompletedTask;
    }
}
