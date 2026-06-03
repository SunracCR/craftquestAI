namespace CraftQuest.Application.Options;

/// <summary>Seguridad de webhooks de pagos (PayPal, Google Pub/Sub, App Store).</summary>
public class PaymentWebhookOptions
{
    /// <summary>
    /// Si true y <see cref="PaymentOptions.UseMockPayments"/> es false, se exige verificación de firma/JWT.
    /// </summary>
    public bool RequireVerification { get; set; }

    /// <summary>
    /// Audience esperado del JWT de Google Pub/Sub push (URL pública del endpoint, sin barra final).
    /// Ejemplo: https://api.craftquest.app/api/webhooks/google-play
    /// </summary>
    public string GooglePubSubAudience { get; set; } = string.Empty;
}
