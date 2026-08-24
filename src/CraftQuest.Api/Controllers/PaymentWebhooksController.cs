using System.Text;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Infrastructure.Services.Payments;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Cors;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/webhooks")]
[AllowAnonymous]
[DisableCors]
public class PaymentWebhooksController(
    IPaymentService paymentService,
    PaymentWebhookSecurityService webhookSecurity,
    ILogger<PaymentWebhooksController> logger) : ControllerBase
{
    [HttpPost("paypal")]
    public async Task<IActionResult> PayPal(CancellationToken cancellationToken)
    {
        using var reader = new StreamReader(Request.Body, Encoding.UTF8);
        var body = await reader.ReadToEndAsync(cancellationToken);

        var eventId = Request.Headers.TryGetValue("PAYPAL-TRANSMISSION-ID", out var transmissionId)
            ? transmissionId.ToString()
            : Guid.NewGuid().ToString();

        var eventType = "UNKNOWN";
        if (!string.IsNullOrWhiteSpace(body))
        {
            try
            {
                using var doc = System.Text.Json.JsonDocument.Parse(body);
                if (doc.RootElement.TryGetProperty("id", out var webhookIdEl))
                {
                    var webhookId = webhookIdEl.GetString();
                    if (!string.IsNullOrWhiteSpace(webhookId))
                    {
                        eventId = webhookId;
                    }
                }

                if (doc.RootElement.TryGetProperty("event_type", out var eventTypeEl))
                {
                    var parsedEventType = eventTypeEl.GetString();
                    if (!string.IsNullOrWhiteSpace(parsedEventType))
                    {
                        eventType = parsedEventType;
                    }
                }
            }
            catch (System.Text.Json.JsonException)
            {
                // Fallback al header si el body no es JSON válido.
            }
        }

        if (eventType == "UNKNOWN"
            && Request.Headers.TryGetValue("PAYPAL-EVENT-TYPE", out var eventTypeHeader))
        {
            var headerEventType = eventTypeHeader.ToString();
            if (!string.IsNullOrWhiteSpace(headerEventType))
            {
                eventType = headerEventType;
            }
        }

        if (string.IsNullOrWhiteSpace(body))
        {
            return BadRequest();
        }

        try
        {
            var paypalHeaders = Request.Headers.ToDictionary(
                h => h.Key,
                h => h.Value.ToString(),
                StringComparer.OrdinalIgnoreCase);
            await webhookSecurity.VerifyPayPalAsync(paypalHeaders, body, cancellationToken);
            await paymentService.ProcessPayPalWebhookAsync(
                eventId,
                eventType,
                body,
                cancellationToken);
        }
        catch (AppException ex) when (ex.StatusCode is 401 or 503)
        {
            return StatusCode(ex.StatusCode, new { error = ex.Message });
        }

        return Ok();
    }

    // Absolute route so the path is exactly /api/webhooks/google-play (Pub/Sub push URL).
    [HttpPost("/api/webhooks/google-play")]
    public async Task<IActionResult> GooglePlay(CancellationToken cancellationToken)
    {
        using var reader = new StreamReader(Request.Body, Encoding.UTF8);
        var body = await reader.ReadToEndAsync(cancellationToken);
        if (string.IsNullOrWhiteSpace(body))
        {
            logger.LogWarning("Google Play Pub/Sub webhook received an empty request body.");
            return Ok();
        }

        try
        {
            Request.Headers.TryGetValue("Authorization", out var authHeader);
            await webhookSecurity.VerifyGooglePubSubAsync(authHeader.ToString(), cancellationToken);
            await paymentService.ProcessGooglePlayPubSubAsync(body, cancellationToken);
        }
        catch (AppException ex) when (ex.StatusCode is 401 or 503)
        {
            logger.LogWarning(
                "Google Play Pub/Sub webhook rejected: {StatusCode} {Message}",
                ex.StatusCode,
                ex.Message);
            return StatusCode(ex.StatusCode, new { error = ex.Message });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Google Play Pub/Sub webhook processing failed.");
            return StatusCode(500);
        }

        return Ok();
    }

    [HttpPost("app-store")]
    public async Task<IActionResult> AppStore(CancellationToken cancellationToken)
    {
        using var reader = new StreamReader(Request.Body, Encoding.UTF8);
        var body = await reader.ReadToEndAsync(cancellationToken);
        if (string.IsNullOrWhiteSpace(body))
        {
            logger.LogWarning("App Store webhook received an empty request body.");
            return Ok();
        }

        try
        {
            webhookSecurity.VerifyAppleSignedPayload(body);
            await paymentService.ProcessAppleStoreNotificationAsync(body, cancellationToken);
        }
        catch (AppException ex) when (ex.StatusCode is 401 or 503)
        {
            logger.LogWarning(
                "App Store webhook rejected: {StatusCode} {Message}",
                ex.StatusCode,
                ex.Message);
            return StatusCode(ex.StatusCode, new { error = ex.Message });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "App Store webhook processing failed.");
            return StatusCode(500);
        }

        return Ok();
    }
}
