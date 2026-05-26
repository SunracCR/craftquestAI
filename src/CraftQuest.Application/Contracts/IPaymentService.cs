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

    Task<VerifyMobilePurchaseResponse> VerifyMobilePurchaseAsync(
        Guid userId,
        VerifyMobilePurchaseRequest request,
        CancellationToken cancellationToken = default);
}
