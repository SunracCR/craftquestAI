using System.Text;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Infrastructure.Services.Payments;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/webhooks")]
[AllowAnonymous]
public class PaymentWebhooksController(
    IPaymentService paymentService,
    PaymentWebhookSecurityService webhookSecurity) : ControllerBase
{
    [HttpPost("paypal")]
    public async Task<IActionResult> PayPal(CancellationToken cancellationToken)
    {
        using var reader = new StreamReader(Request.Body, Encoding.UTF8);
        var body = await reader.ReadToEndAsync(cancellationToken);

        var eventId = Request.Headers.TryGetValue("PAYPAL-TRANSMISSION-ID", out var transmissionId)
            ? transmissionId.ToString()
            : Guid.NewGuid().ToString();

        var eventType = Request.Headers.TryGetValue("PAYPAL-EVENT-TYPE", out var eventTypeHeader)
            ? eventTypeHeader.ToString()
            : "UNKNOWN";

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

    [HttpPost("google-play")]
    public async Task<IActionResult> GooglePlay(CancellationToken cancellationToken)
    {
        using var reader = new StreamReader(Request.Body, Encoding.UTF8);
        var body = await reader.ReadToEndAsync(cancellationToken);
        if (string.IsNullOrWhiteSpace(body))
        {
            return BadRequest();
        }

        try
        {
            Request.Headers.TryGetValue("Authorization", out var authHeader);
            await webhookSecurity.VerifyGooglePubSubAsync(authHeader.ToString(), cancellationToken);
            await paymentService.ProcessGooglePlayPubSubAsync(body, cancellationToken);
        }
        catch (AppException ex) when (ex.StatusCode is 401 or 503)
        {
            return StatusCode(ex.StatusCode, new { error = ex.Message });
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
            return BadRequest();
        }

        try
        {
            webhookSecurity.VerifyAppleSignedPayload(body);
            await paymentService.ProcessAppleStoreNotificationAsync(body, cancellationToken);
        }
        catch (AppException ex) when (ex.StatusCode is 401 or 503)
        {
            return StatusCode(ex.StatusCode, new { error = ex.Message });
        }

        return Ok();
    }
}
