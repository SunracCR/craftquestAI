using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Models.PrepPlus;

namespace CraftQuest.Application.Contracts;

public interface IPrepPlusPaymentService
{
    Task<PayPalCreateOrderResponse> CreatePayPalOrderAsync(
        Guid userId,
        Guid catalogItemId,
        Guid offerId,
        string? referralCode = null,
        CancellationToken cancellationToken = default);

    Task<PrepCheckoutResultDto> CapturePayPalOrderAsync(
        Guid userId,
        PayPalCaptureOrderRequest request,
        CancellationToken cancellationToken = default);

    Task<PrepCheckoutResultDto> VerifyMobilePurchaseAsync(
        Guid userId,
        PrepMobilePurchaseRequest request,
        CancellationToken cancellationToken = default);
}
