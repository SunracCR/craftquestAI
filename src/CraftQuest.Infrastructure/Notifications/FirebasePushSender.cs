using CraftQuest.Application.Options;
using CraftQuest.Application.Contracts;
using CraftQuest.Infrastructure.Persistence;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Notifications;

public sealed class FirebasePushSender(
    CraftQuestDbContext dbContext,
    IOptions<PushOptions> pushOptions,
    ILogger<FirebasePushSender> logger) : IPushSender
{
    private static bool _initialized;
    private static readonly object InitLock = new();

    public async Task SendAsync(
        Guid userId,
        string title,
        string body,
        IReadOnlyDictionary<string, string>? data,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureInitialized())
        {
            return;
        }

        var tokens = await dbContext.DeviceTokens
            .AsNoTracking()
            .Where(t => t.UserId == userId)
            .Select(t => t.Token)
            .ToListAsync(cancellationToken);

        if (tokens.Count == 0)
        {
            return;
        }

        var message = new MulticastMessage
        {
            Tokens = tokens,
            Notification = new FirebaseAdmin.Messaging.Notification
            {
                Title = title,
                Body = body,
            },
            Data = data?.ToDictionary(k => k.Key, v => v.Value) ?? [],
        };

        try
        {
            var response = await FirebaseMessaging.DefaultInstance.SendEachForMulticastAsync(
                message,
                cancellationToken);

            for (var i = 0; i < response.Responses.Count; i++)
            {
                if (response.Responses[i].IsSuccess)
                {
                    continue;
                }

                var error = response.Responses[i].Exception?.MessagingErrorCode;
                if (error is MessagingErrorCode.Unregistered or MessagingErrorCode.InvalidArgument)
                {
                    await RemoveInvalidTokenAsync(tokens[i], cancellationToken);
                }
            }
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "FCM multicast failed for user {UserId}", userId);
        }
    }

    public async Task RemoveInvalidTokenAsync(string token, CancellationToken cancellationToken = default)
    {
        var entity = await dbContext.DeviceTokens
            .FirstOrDefaultAsync(t => t.Token == token, cancellationToken);
        if (entity is null)
        {
            return;
        }

        dbContext.DeviceTokens.Remove(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private bool EnsureInitialized()
    {
        if (_initialized)
        {
            return FirebaseApp.DefaultInstance is not null;
        }

        lock (InitLock)
        {
            if (_initialized)
            {
                return FirebaseApp.DefaultInstance is not null;
            }

            _initialized = true;
            var options = pushOptions.Value;
            if (!options.Enabled || string.IsNullOrWhiteSpace(options.CredentialsPath))
            {
                logger.LogInformation("Firebase push disabled (Push:Enabled or CredentialsPath missing).");
                return false;
            }

            try
            {
                if (FirebaseApp.DefaultInstance is null)
                {
                    FirebaseApp.Create(new AppOptions
                    {
                        Credential = GoogleCredential.FromFile(options.CredentialsPath),
                    });
                }

                return true;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to initialize Firebase Admin SDK.");
                return false;
            }
        }
    }
}
