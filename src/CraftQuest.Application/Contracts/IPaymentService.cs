using CraftQuest.Application.Models.Billing;

namespace CraftQuest.Application.Contracts;

public interface IPaymentService
{
    Task<IReadOnlyList<UpgradeablePlanDto>> GetUpgradeablePlansAsync(
        Guid? userId = null,
        CancellationToken cancellationToken = default);

    Task<PayPalCreateOrderResponse> CreatePayPalOrderAsync(
        Guid userId,
        PayPalCreateOrderRequest request,
        CancellationToken cancellationToken = default);

    Task<PayPalCaptureOrderResponse> CapturePayPalOrderAsync(
        Guid userId,
        PayPalCaptureOrderRequest request,
        CancellationToken cancellationToken = default);

    Task<PayPalCreateSubscriptionResponse> CreatePayPalSubscriptionAsync(
        Guid userId,
        PayPalCreateSubscriptionRequest request,
        CancellationToken cancellationToken = default);

    Task<PayPalActivateSubscriptionResponse> ActivatePayPalSubscriptionAsync(
        Guid userId,
        PayPalActivateSubscriptionRequest request,
        CancellationToken cancellationToken = default);

    Task RevokeProviderAutoRenewAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task<ProviderAutoRenewRestoreResult> TryRestoreProviderAutoRenewAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task ProcessPayPalWebhookAsync(
        string eventId,
        string eventType,
        string rawBody,
        CancellationToken cancellationToken = default);

    Task ProcessGooglePlayPubSubAsync(
        string rawBody,
        CancellationToken cancellationToken = default);

    Task ProcessAppleStoreNotificationAsync(
        string rawBody,
        CancellationToken cancellationToken = default);

    Task<VerifyMobilePurchaseResponse> VerifyMobilePurchaseAsync(
        Guid userId,
        VerifyMobilePurchaseRequest request,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AiCreditPackDto>> GetAiCreditPacksAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task<PayPalCreateOrderResponse> CreatePayPalAiCreditOrderAsync(
        Guid userId,
        PayPalCreateAiCreditOrderRequest request,
        CancellationToken cancellationToken = default);

    Task<PayPalCaptureAiCreditOrderResponse> CapturePayPalAiCreditOrderAsync(
        Guid userId,
        PayPalCaptureOrderRequest request,
        CancellationToken cancellationToken = default);

    Task<VerifyMobileAiCreditPurchaseResponse> VerifyMobileAiCreditPurchaseAsync(
        Guid userId,
        VerifyMobileAiCreditPurchaseRequest request,
        CancellationToken cancellationToken = default);
}
