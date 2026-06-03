namespace CraftQuest.Application.Contracts;

public interface IEmailSender
{
    Task SendAsync(
        string toEmail,
        string subject,
        string plainTextBody,
        CancellationToken cancellationToken = default);
}
