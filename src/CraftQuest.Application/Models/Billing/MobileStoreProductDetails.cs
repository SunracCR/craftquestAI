namespace CraftQuest.Application.Models.Billing;

/// <summary>Resultado normalizado tras validar una compra consumible en Google Play o App Store.</summary>
public sealed class MobileStoreProductDetails
{
    public required bool IsValid { get; init; }
    public required string TransactionId { get; init; }
}
