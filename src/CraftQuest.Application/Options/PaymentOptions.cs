namespace CraftQuest.Application.Options;

public class PaymentOptions
{
    public const string SectionName = "Payments";

    public bool UseMockPayments { get; set; } = true;
    public string CurrencyCode { get; set; } = "USD";
    public PaymentWebhookOptions Webhooks { get; set; } = new();
    public PayPalOptions PayPal { get; set; } = new();
    public MobileStoreOptions Mobile { get; set; } = new();
    public Dictionary<string, PlanProductMapping> PlanProducts { get; set; } = new();
    public List<AiCreditPackDefinition> AiCreditPacks { get; set; } = [];
}

public class AiCreditPackDefinition
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public int Credits { get; set; }
    public decimal PriceUsd { get; set; }
    public int SortOrder { get; set; }
    public string GooglePlayProductId { get; set; } = string.Empty;
    public string AppStoreProductId { get; set; } = string.Empty;
}

public class PayPalOptions
{
    public string ClientId { get; set; } = string.Empty;
    public string ClientSecret { get; set; } = string.Empty;
    public string ApiBaseUrl { get; set; } = "https://api-m.sandbox.paypal.com";
    public string ReturnUrl { get; set; } = string.Empty;
    public string CancelUrl { get; set; } = string.Empty;
    /// <summary>ID del webhook registrado en PayPal (requerido si Webhooks.RequireVerification está activo).</summary>
    public string WebhookId { get; set; } = string.Empty;

    /// <summary>Si true, llama a verify-webhook-signature cuando RequireVerification está activo.</summary>
    public bool VerifyWebhooks { get; set; } = true;
}

public class MobileStoreOptions
{
    public string GooglePlayPackageName { get; set; } = "com.craftquestai.craftquestai_app";

    /// <summary>Ruta al JSON de cuenta de servicio de Google Play Console.</summary>
    public string GooglePlayServiceAccountJsonPath { get; set; } = string.Empty;

    public string AppleBundleId { get; set; } = "com.craftquestai.craftquestaiApp";

    /// <summary>App Store Connect → Users and Access → Keys (Issuer ID).</summary>
    public string AppleIssuerId { get; set; } = string.Empty;

    public string AppleKeyId { get; set; } = string.Empty;

    /// <summary>Ruta al archivo .p8 de App Store Connect.</summary>
    public string ApplePrivateKeyPath { get; set; } = string.Empty;

    /// <summary>Sandbox | Production</summary>
    public string AppleEnvironment { get; set; } = "Sandbox";

    /// <summary>Fallback verifyReceipt (legacy) si no hay transactionId.</summary>
    public string AppleSharedSecret { get; set; } = string.Empty;
}

public class PlanProductMapping
{
    /// <summary>Plan ID de PayPal Subscriptions (mensual).</summary>
    public string PayPalMonthlyPlanId { get; set; } = string.Empty;

    /// <summary>Plan ID de PayPal Subscriptions (anual).</summary>
    public string PayPalAnnualPlanId { get; set; } = string.Empty;

    /// <summary>Compatibilidad: si solo hay un ID, se usa para mensual.</summary>
    public string PayPalPlanCode
    {
        get => PayPalMonthlyPlanId;
        set => PayPalMonthlyPlanId = value;
    }

    public string GooglePlayProductId { get; set; } = string.Empty;
    public string GooglePlayAnnualProductId { get; set; } = string.Empty;
    public string AppStoreProductId { get; set; } = string.Empty;
    public string AppStoreAnnualProductId { get; set; } = string.Empty;
}
