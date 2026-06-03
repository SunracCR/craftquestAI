using System.Text;
using System.Text.Json;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Payments;

public sealed class MobileStoreWebhookProcessor(
    CraftQuestDbContext dbContext,
    IBillingService billingService,
    AppleAppStoreJwsVerifier appleJwsVerifier,
    IOptions<PaymentOptions> options)
{
    public async Task ProcessGooglePlayPubSubAsync(
        string rawBody,
        CancellationToken cancellationToken = default)
    {
        using var doc = JsonDocument.Parse(rawBody);
        if (!doc.RootElement.TryGetProperty("message", out var message)
            || !message.TryGetProperty("data", out var dataEl))
        {
            throw new AppException("Invalid Google Play Pub/Sub payload.", 400);
        }

        var decoded = Encoding.UTF8.GetString(
            Convert.FromBase64String(dataEl.GetString()!));

        using var notification = JsonDocument.Parse(decoded);
        var root = notification.RootElement;
        if (!root.TryGetProperty("subscriptionNotification", out var subNotification))
        {
            return;
        }

        var purchaseToken = subNotification.GetProperty("purchaseToken").GetString();
        var notificationType = subNotification.GetProperty("notificationType").GetInt32();
        if (string.IsNullOrWhiteSpace(purchaseToken))
        {
            return;
        }

        var eventId = root.TryGetProperty("eventIdMillis", out var eventIdEl)
            ? $"gp-{eventIdEl.GetInt64()}"
            : $"gp-{Guid.NewGuid():N}";

        if (await IsDuplicateEventAsync("google_play", eventId, cancellationToken))
        {
            return;
        }

        await RecordEventAsync("google_play", eventId, $"type-{notificationType}", cancellationToken);

        var subscription = await dbContext.UserSubscriptions
            .Where(s => s.ProviderSubscriptionId == purchaseToken
                        && s.ProviderCode == "google_play")
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (subscription is null)
        {
            await dbContext.SaveChangesAsync(cancellationToken);
            return;
        }

        // 1=RECOVERED, 2=RENEWED, 4=NEW, 7=RESTARTED
        if (notificationType is 1 or 2 or 4 or 7)
        {
            await billingService.RenewSubscriptionPeriodAsync(
                purchaseToken,
                "google_play",
                null,
                eventId,
                cancellationToken);
        }
        else if (notificationType is 3 or 12 or 13)
        {
            subscription.AutoRenewEnabled = false;
            subscription.CancelAtPeriodEnd = true;
            await dbContext.SaveChangesAsync(cancellationToken);
        }
        else
        {
            await dbContext.SaveChangesAsync(cancellationToken);
        }
    }

    public async Task ProcessAppleNotificationAsync(
        string rawBody,
        CancellationToken cancellationToken = default)
    {
        using var doc = JsonDocument.Parse(rawBody);
        if (!doc.RootElement.TryGetProperty("signedPayload", out var signedPayloadEl))
        {
            throw new AppException("Invalid Apple notification payload.", 400);
        }

        var payload = AppleAppStoreJwsVerifier.DecodePayload(signedPayloadEl.GetString()!);
        var notificationType = payload.TryGetProperty("notificationType", out var typeEl)
            ? typeEl.GetString()
            : null;
        var notificationUuid = payload.TryGetProperty("notificationUUID", out var uuidEl)
            ? uuidEl.GetString()
            : Guid.NewGuid().ToString();

        if (string.IsNullOrWhiteSpace(notificationUuid)
            || await IsDuplicateEventAsync("app_store", notificationUuid, cancellationToken))
        {
            return;
        }

        await RecordEventAsync("app_store", notificationUuid, notificationType ?? "unknown", cancellationToken);

        if (!payload.TryGetProperty("data", out var data)
            || !data.TryGetProperty("signedTransactionInfo", out var signedTxEl))
        {
            await dbContext.SaveChangesAsync(cancellationToken);
            return;
        }

        var signedTx = signedTxEl.GetString()!;
        VerifyNestedJwsIfEnabled(signedTx);
        var tx = AppleAppStoreJwsVerifier.DecodePayload(signedTx);
        var originalTransactionId = ReadString(tx, "originalTransactionId");
        if (string.IsNullOrWhiteSpace(originalTransactionId))
        {
            await dbContext.SaveChangesAsync(cancellationToken);
            return;
        }

        var expiresMs = ReadLong(tx, "expiresDate");
        var periodEnd = expiresMs > 0
            ? DateTimeOffset.FromUnixTimeMilliseconds(expiresMs).UtcDateTime
            : (DateTime?)null;

        switch (notificationType)
        {
            case "DID_RENEW":
            case "SUBSCRIBED":
            case "DID_CHANGE_RENEWAL_PREF":
                await billingService.RenewSubscriptionPeriodAsync(
                    originalTransactionId,
                    "app_store",
                    periodEnd,
                    ReadString(tx, "transactionId"),
                    cancellationToken);
                break;
            case "EXPIRED":
            case "REVOKE":
            case "DID_FAIL_TO_RENEW":
                var subscription = await dbContext.UserSubscriptions
                    .Where(s => s.ProviderSubscriptionId == originalTransactionId
                                && s.ProviderCode == "app_store"
                                && s.Status == "active")
                    .FirstOrDefaultAsync(cancellationToken);
                if (subscription is not null)
                {
                    subscription.AutoRenewEnabled = false;
                    subscription.CancelAtPeriodEnd = true;
                    if (periodEnd.HasValue)
                    {
                        subscription.EndsAt = periodEnd;
                    }
                }

                await dbContext.SaveChangesAsync(cancellationToken);
                break;
            default:
                await dbContext.SaveChangesAsync(cancellationToken);
                break;
        }
    }

    private async Task<bool> IsDuplicateEventAsync(
        string provider,
        string eventId,
        CancellationToken cancellationToken) =>
        await dbContext.ProviderWebhookEvents.AnyAsync(
            e => e.ProviderCode == provider && e.EventId == eventId,
            cancellationToken);

    private async Task RecordEventAsync(
        string provider,
        string eventId,
        string eventType,
        CancellationToken cancellationToken)
    {
        dbContext.ProviderWebhookEvents.Add(new ProviderWebhookEvent
        {
            ProviderWebhookEventId = Guid.NewGuid(),
            ProviderCode = provider,
            EventId = eventId,
            EventType = eventType,
            ProcessedAt = DateTime.UtcNow,
        });
    }

    private void VerifyNestedJwsIfEnabled(string jws)
    {
        if (!options.Value.UseMockPayments && options.Value.Webhooks.RequireVerification)
        {
            appleJwsVerifier.VerifySignedPayload(jws);
        }
    }

    private static string? ReadString(JsonElement el, string name) =>
        el.TryGetProperty(name, out var prop) ? prop.GetString() : null;

    private static long ReadLong(JsonElement el, string name)
    {
        if (!el.TryGetProperty(name, out var prop))
        {
            return 0;
        }

        return prop.ValueKind switch
        {
            JsonValueKind.Number => prop.GetInt64(),
            JsonValueKind.String when long.TryParse(prop.GetString(), out var n) => n,
            _ => 0,
        };
    }
}
