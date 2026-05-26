namespace CraftQuest.Application.Options;

public class PaymentOptions
{
    public const string SectionName = "Payments";

    public bool UseMockPayments { get; set; } = true;
    public string CurrencyCode { get; set; } = "USD";
    public PayPalOptions PayPal { get; set; } = new();
    public MobileStoreOptions Mobile { get; set; } = new();
    public Dictionary<string, PlanProductMapping> PlanProducts { get; set; } = new();
}

public class PayPalOptions
{
    public string ClientId { get; set; } = string.Empty;
    public string ClientSecret { get; set; } = string.Empty;
    public string ApiBaseUrl { get; set; } = "https://api-m.sandbox.paypal.com";
    public string ReturnUrl { get; set; } = string.Empty;
    public string CancelUrl { get; set; } = string.Empty;
}

public class MobileStoreOptions
{
    public string GooglePlayPackageName { get; set; } = "com.craftquest.app";
    public string AppleSharedSecret { get; set; } = string.Empty;
}

public class PlanProductMapping
{
    public string PayPalPlanCode { get; set; } = string.Empty;
    public string GooglePlayProductId { get; set; } = string.Empty;
    public string AppStoreProductId { get; set; } = string.Empty;
}
