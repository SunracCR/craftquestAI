using System.Text;
using System.Text.Json;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Notifications;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Notifications;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Payments;

public sealed class MobileStoreWebhookProcessor(
    CraftQuestDbContext dbContext,
    IBillingService billingService,
    GooglePlaySubscriptionVerifier googlePlayVerifier,
    INotificationService notificationService,
    AppleAppStoreJwsVerifier appleJwsVerifier,
    IOptions<PaymentOptions> options,
    ILogger<MobileStoreWebhookProcessor> logger)
{
    public async Task ProcessGooglePlayPubSubAsync(
        string rawBody,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(rawBody))
        {
            logger.LogWarning("Google Play Pub/Sub webhook received an empty body.");
            return;
        }

        JsonDocument pubSubEnvelope;
        try
        {
            pubSubEnvelope = JsonDocument.Parse(rawBody);
        }
        catch (JsonException ex)
        {
            logger.LogWarning(ex, "Google Play Pub/Sub webhook body is not valid JSON.");
            return;
        }

        using (pubSubEnvelope)
        {
            if (!pubSubEnvelope.RootElement.TryGetProperty("message", out var message)
                || !message.TryGetProperty("data", out var dataEl))
            {
                logger.LogWarning("Google Play Pub/Sub payload is missing message.data.");
                return;
            }

            var dataBase64 = dataEl.GetString();
            if (string.IsNullOrWhiteSpace(dataBase64))
            {
                logger.LogWarning("Google Play Pub/Sub payload has an empty message.data field.");
                return;
            }

            string decoded;
            try
            {
                decoded = Encoding.UTF8.GetString(Convert.FromBase64String(dataBase64));
            }
            catch (FormatException ex)
            {
                logger.LogWarning(ex, "Google Play Pub/Sub message.data is not valid Base64.");
                return;
            }

            JsonDocument notification;
            try
            {
                notification = JsonDocument.Parse(decoded);
            }
            catch (JsonException ex)
            {
                logger.LogWarning(ex, "Google Play Pub/Sub decoded payload is not valid JSON.");
                return;
            }

            using (notification)
            {
                var root = notification.RootElement;

                if (root.TryGetProperty("testNotification", out _))
                {
                    logger.LogInformation("Google Play Pub/Sub test notification received.");
                    return;
                }

                if (!root.TryGetProperty("subscriptionNotification", out var subNotification))
                {
                    logger.LogInformation(
                        "Google Play Pub/Sub notification ignored (no subscriptionNotification).");
                    return;
                }

                if (!subNotification.TryGetProperty("purchaseToken", out var purchaseTokenEl)
                    || !subNotification.TryGetProperty("notificationType", out var notificationTypeEl))
                {
                    logger.LogWarning(
                        "Google Play subscriptionNotification is missing purchaseToken or notificationType.");
                    return;
                }

                var purchaseToken = purchaseTokenEl.GetString();
                if (!notificationTypeEl.TryGetInt32(out var notificationType)
                    || string.IsNullOrWhiteSpace(purchaseToken))
                {
                    return;
                }

                await ProcessGooglePlaySubscriptionNotificationAsync(
                    root,
                    purchaseToken,
                    notificationType,
                    cancellationToken);
            }
        }
    }

    private async Task ProcessGooglePlaySubscriptionNotificationAsync(
        JsonElement root,
        string purchaseToken,
        int notificationType,
        CancellationToken cancellationToken)
    {

        var eventTimeMillis = ReadLong(root, "eventTimeMillis");
        var eventIdMillis = ReadLong(root, "eventIdMillis");
        var eventId = eventTimeMillis > 0
            ? $"gp-{eventTimeMillis}"
            : eventIdMillis > 0
                ? $"gp-{eventIdMillis}"
                : $"gp-{Guid.NewGuid():N}";

        if (await IsDuplicateEventAsync("google_play", eventId, cancellationToken))
        {
            return;
        }

        await RecordEventAsync("google_play", eventId, $"type-{notificationType}", cancellationToken);

        var subscription = await dbContext.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.ProviderSubscriptionId == purchaseToken
                        && s.ProviderCode == "google_play")
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (subscription is null)
        {
            logger.LogInformation(
                "Google Play Pub/Sub event {EventId} ignored: no subscription for purchase token.",
                eventId);
            await dbContext.SaveChangesAsync(cancellationToken);
            return;
        }

        // 1=RECOVERED, 2=RENEWED, 4=NEW, 7=RESTARTED
        if (notificationType is 1 or 2 or 4 or 7)
        {
            DateTime? periodEnd = null;
            try
            {
                var googleSub = await googlePlayVerifier.GetSubscriptionAsync(
                    purchaseToken,
                    cancellationToken);
                periodEnd = googleSub.LineItems?.FirstOrDefault()?.ExpiryTimeDateTimeOffset?.UtcDateTime;
            }
            catch (Exception ex)
            {
                logger.LogWarning(
                    ex,
                    "Could not fetch Google Play subscription for {PurchaseToken}; using local period fallback.",
                    purchaseToken);
            }

            await billingService.RenewSubscriptionPeriodAsync(
                purchaseToken,
                "google_play",
                periodEnd,
                eventId,
                cancellationToken);
        }
        else if (notificationType == 12)
        {
            await billingService.RevokeSubscriptionImmediatelyAsync(
                purchaseToken,
                "google_play",
                cancellationToken);
        }
        else if (notificationType is 3 or 13)
        {
            subscription.AutoRenewEnabled = false;
            subscription.CancelAtPeriodEnd = true;
            await dbContext.SaveChangesAsync(cancellationToken);
        }
        else if (notificationType is 5 or 6)
        {
            subscription.PaymentIssuePending = true;
            await dbContext.SaveChangesAsync(cancellationToken);

            await NotificationPublisher.TryNotifyAsync(
                () => notificationService.NotifyAsync(
                    subscription.UserId,
                    NotificationTypes.PaymentIssuePending,
                    new NotificationPayload
                    {
                        PlanName = subscription.Plan?.Name ?? subscription.Plan?.Code,
                        Route = "profile/billing",
                    },
                    $"payment_issue:{subscription.UserId}:{eventId}",
                    cancellationToken),
                logger,
                "payment_issue_pending");
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
        if (string.IsNullOrWhiteSpace(rawBody))
        {
            logger.LogWarning("App Store webhook received an empty body.");
            return;
        }

        JsonDocument doc;
        try
        {
            doc = JsonDocument.Parse(rawBody);
        }
        catch (JsonException ex)
        {
            logger.LogWarning(ex, "App Store webhook body is not valid JSON.");
            return;
        }

        using (doc)
        {
            if (!doc.RootElement.TryGetProperty("signedPayload", out var signedPayloadEl))
            {
                logger.LogWarning("App Store webhook payload is missing signedPayload.");
                return;
            }

            JsonElement payload;
            try
            {
                payload = AppleAppStoreJwsVerifier.DecodePayload(signedPayloadEl.GetString()!);
            }
            catch (AppException ex)
            {
                logger.LogWarning(ex, "App Store webhook signedPayload could not be decoded.");
                return;
            }

            var notificationType = payload.TryGetProperty("notificationType", out var typeEl)
                ? typeEl.GetString()
                : null;
            var subtype = payload.TryGetProperty("subtype", out var subtypeEl)
                ? subtypeEl.GetString()
                : null;

            if (string.Equals(notificationType, "TEST", StringComparison.Ordinal))
            {
                logger.LogInformation("App Store test notification received.");
                return;
            }

            var notificationUuid = payload.TryGetProperty("notificationUUID", out var uuidEl)
                ? uuidEl.GetString()
                : Guid.NewGuid().ToString();

            if (string.IsNullOrWhiteSpace(notificationUuid)
                || await IsDuplicateEventAsync("app_store", notificationUuid, cancellationToken))
            {
                return;
            }

            var eventType = string.IsNullOrWhiteSpace(subtype)
                ? notificationType ?? "unknown"
                : $"{notificationType}:{subtype}";
            await RecordEventAsync("app_store", notificationUuid, eventType, cancellationToken);

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

            bool? autoRenewEnabled = null;
            if (data.TryGetProperty("signedRenewalInfo", out var signedRenewalEl))
            {
                var signedRenewal = signedRenewalEl.GetString();
                if (!string.IsNullOrWhiteSpace(signedRenewal))
                {
                    VerifyNestedJwsIfEnabled(signedRenewal);
                    var renewalInfo = AppleAppStoreJwsVerifier.DecodePayload(signedRenewal);
                    if (renewalInfo.TryGetProperty("autoRenewStatus", out var autoRenewEl))
                    {
                        autoRenewEnabled = ReadInt(autoRenewEl) == 1;
                    }
                }
            }

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
                    if (autoRenewEnabled.HasValue)
                    {
                        await ApplyAutoRenewStatusAsync(
                            originalTransactionId,
                            autoRenewEnabled.Value,
                            cancellationToken);
                    }

                    break;
                case "REVOKE":
                case "REFUND":
                    await billingService.RevokeSubscriptionImmediatelyAsync(
                        originalTransactionId,
                        "app_store",
                        cancellationToken);
                    break;
                case "DID_FAIL_TO_RENEW" when string.Equals(subtype, "GRACE_PERIOD", StringComparison.Ordinal):
                    await ApplyPaymentIssuePendingAsync(
                        originalTransactionId,
                        notificationUuid,
                        autoRenewEnabled,
                        cancellationToken);
                    break;
                case "EXPIRED":
                case "DID_FAIL_TO_RENEW":
                    await ApplyCancelAtPeriodEndAsync(
                        originalTransactionId,
                        periodEnd,
                        autoRenewEnabled,
                        cancellationToken);
                    break;
                default:
                    if (autoRenewEnabled.HasValue)
                    {
                        await ApplyAutoRenewStatusAsync(
                            originalTransactionId,
                            autoRenewEnabled.Value,
                            cancellationToken);
                    }
                    else
                    {
                        await dbContext.SaveChangesAsync(cancellationToken);
                    }

                    break;
            }
        }
    }

    private async Task ApplyCancelAtPeriodEndAsync(
        string originalTransactionId,
        DateTime? periodEnd,
        bool? autoRenewEnabled,
        CancellationToken cancellationToken)
    {
        var subscription = await FindActiveAppStoreSubscriptionAsync(
            originalTransactionId,
            cancellationToken);
        if (subscription is not null)
        {
            subscription.AutoRenewEnabled = autoRenewEnabled ?? false;
            subscription.CancelAtPeriodEnd = true;
            if (periodEnd.HasValue)
            {
                subscription.EndsAt = periodEnd;
            }
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task ApplyPaymentIssuePendingAsync(
        string originalTransactionId,
        string eventId,
        bool? autoRenewEnabled,
        CancellationToken cancellationToken)
    {
        var subscription = await dbContext.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.ProviderSubscriptionId == originalTransactionId
                        && s.ProviderCode == "app_store"
                        && s.Status == "active")
            .FirstOrDefaultAsync(cancellationToken);
        if (subscription is null)
        {
            await dbContext.SaveChangesAsync(cancellationToken);
            return;
        }

        subscription.PaymentIssuePending = true;
        if (autoRenewEnabled.HasValue)
        {
            subscription.AutoRenewEnabled = autoRenewEnabled.Value;
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        await NotificationPublisher.TryNotifyAsync(
            () => notificationService.NotifyAsync(
                subscription.UserId,
                NotificationTypes.PaymentIssuePending,
                new NotificationPayload
                {
                    PlanName = subscription.Plan?.Name ?? subscription.Plan?.Code,
                    Route = "profile/billing",
                },
                $"payment_issue:{subscription.UserId}:{eventId}",
                cancellationToken),
            logger,
            "payment_issue_pending");
    }

    private async Task ApplyAutoRenewStatusAsync(
        string originalTransactionId,
        bool autoRenewEnabled,
        CancellationToken cancellationToken)
    {
        var subscription = await FindActiveAppStoreSubscriptionAsync(
            originalTransactionId,
            cancellationToken);
        if (subscription is not null)
        {
            subscription.AutoRenewEnabled = autoRenewEnabled;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private Task<UserSubscription?> FindActiveAppStoreSubscriptionAsync(
        string originalTransactionId,
        CancellationToken cancellationToken) =>
        dbContext.UserSubscriptions
            .Where(s => s.ProviderSubscriptionId == originalTransactionId
                        && s.ProviderCode == "app_store"
                        && s.Status == "active")
            .FirstOrDefaultAsync(cancellationToken);

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

        return ReadLong(prop);
    }

    private static long ReadLong(JsonElement prop) =>
        prop.ValueKind switch
        {
            JsonValueKind.Number => prop.GetInt64(),
            JsonValueKind.String when long.TryParse(prop.GetString(), out var n) => n,
            _ => 0,
        };

    private static int ReadInt(JsonElement prop) =>
        prop.ValueKind switch
        {
            JsonValueKind.Number => prop.GetInt32(),
            JsonValueKind.String when int.TryParse(prop.GetString(), out var n) => n,
            _ => 0,
        };
}
