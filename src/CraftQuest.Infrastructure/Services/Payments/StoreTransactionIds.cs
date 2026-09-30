using CraftQuest.Application.Exceptions;

namespace CraftQuest.Infrastructure.Services.Payments;

/// <summary>
/// billing.Purchases.ProviderTransactionId es NVARCHAR(300).
/// StoreKit envía el JWS completo como token; aquí se guarda solo el transactionId.
/// </summary>
public static class StoreTransactionIds
{
    public const int MaxLength = 300;

    public static string? Normalize(string? value)
    {
        var resolved = AppleAppStoreJwsVerifier.ResolveStoreTransactionId(value);
        if (string.IsNullOrWhiteSpace(resolved))
        {
            return null;
        }

        if (resolved.Length > MaxLength)
        {
            throw new AppException(
                "Store transaction id is too long to store.",
                400,
                "STORE_PURCHASE_INVALID");
        }

        return resolved;
    }
}
