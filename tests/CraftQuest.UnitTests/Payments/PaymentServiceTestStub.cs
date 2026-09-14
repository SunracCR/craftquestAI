using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Billing;
using Microsoft.Extensions.DependencyInjection;

namespace CraftQuest.UnitTests.Payments;

internal sealed class PaymentServiceTestStub : IPaymentService
{
    public Func<string, string, string?, string?, CancellationToken, Task<bool>>? ActivateFromWebhookHandler { get; init; }

    public Task<bool> TryActivateMobileSubscriptionFromStoreWebhookAsync(
        string providerCode,
        string providerSubscriptionId,
        string? productId,
        string? transactionId,
        CancellationToken cancellationToken = default) =>
        ActivateFromWebhookHandler?.Invoke(
            providerCode,
            providerSubscriptionId,
            productId,
            transactionId,
            cancellationToken) ?? Task.FromResult(false);

    public Task<IReadOnlyList<UpgradeablePlanDto>> GetUpgradeablePlansAsync(
        Guid? userId = null,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task<PayPalCreateOrderResponse> CreatePayPalOrderAsync(
        Guid userId,
        PayPalCreateOrderRequest request,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task<PayPalCaptureOrderResponse> CapturePayPalOrderAsync(
        Guid userId,
        PayPalCaptureOrderRequest request,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task<PayPalCreateSubscriptionResponse> CreatePayPalSubscriptionAsync(
        Guid userId,
        PayPalCreateSubscriptionRequest request,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task<PayPalActivateSubscriptionResponse> ActivatePayPalSubscriptionAsync(
        Guid userId,
        PayPalActivateSubscriptionRequest request,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task RevokeProviderAutoRenewAsync(
        Guid userId,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task<ProviderAutoRenewRestoreResult> TryRestoreProviderAutoRenewAsync(
        Guid userId,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task ProcessPayPalWebhookAsync(
        string eventId,
        string eventType,
        string rawBody,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task ProcessGooglePlayPubSubAsync(
        string rawBody,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task ProcessAppleStoreNotificationAsync(
        string rawBody,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task<VerifyMobilePurchaseResponse> VerifyMobilePurchaseAsync(
        Guid userId,
        VerifyMobilePurchaseRequest request,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task<IReadOnlyList<AiCreditPackDto>> GetAiCreditPacksAsync(
        Guid userId,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task<PayPalCreateOrderResponse> CreatePayPalAiCreditOrderAsync(
        Guid userId,
        PayPalCreateAiCreditOrderRequest request,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task<PayPalCaptureAiCreditOrderResponse> CapturePayPalAiCreditOrderAsync(
        Guid userId,
        PayPalCaptureOrderRequest request,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task<VerifyMobileAiCreditPurchaseResponse> VerifyMobileAiCreditPurchaseAsync(
        Guid userId,
        VerifyMobileAiCreditPurchaseRequest request,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task<int> ReconcilePendingPurchasesAsync(
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task<ReconcilePendingPurchasesResponse> ReconcileUserPendingPurchasesAsync(
        Guid userId,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();
}

internal static class PaymentTestScopeFactory
{
    public static IServiceScopeFactory Create(IPaymentService paymentService)
    {
        var services = new ServiceCollection();
        services.AddSingleton(paymentService);
        return services.BuildServiceProvider().GetRequiredService<IServiceScopeFactory>();
    }

    public static IServiceScopeFactory CreateDefault() =>
        Create(new PaymentServiceTestStub());
}
