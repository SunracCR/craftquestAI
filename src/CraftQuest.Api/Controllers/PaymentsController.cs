using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Billing;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/billing")]
[Authorize]
public class PaymentsController(IPaymentService paymentService) : ApiControllerBase
{
    [HttpGet("plans")]
    [ProducesResponseType(typeof(IReadOnlyList<UpgradeablePlanDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetUpgradeablePlans(CancellationToken cancellationToken)
    {
        Guid? userId = User.Identity?.IsAuthenticated == true ? GetUserId() : null;
        var plans = await paymentService.GetUpgradeablePlansAsync(userId, cancellationToken);
        return Ok(plans);
    }

    [HttpPost("paypal/create-order")]
    [ProducesResponseType(typeof(PayPalCreateOrderResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreatePayPalOrder(
        [FromBody] PayPalCreateOrderRequest request,
        CancellationToken cancellationToken)
    {
        var result = await paymentService.CreatePayPalOrderAsync(
            GetUserId(),
            request,
            cancellationToken);

        return Ok(result);
    }

    [HttpPost("paypal/capture-order")]
    [ProducesResponseType(typeof(PayPalCaptureOrderResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> CapturePayPalOrder(
        [FromBody] PayPalCaptureOrderRequest request,
        CancellationToken cancellationToken)
    {
        var result = await paymentService.CapturePayPalOrderAsync(
            GetUserId(),
            request,
            cancellationToken);

        return Ok(result);
    }

    [HttpPost("paypal/create-subscription")]
    [ProducesResponseType(typeof(PayPalCreateSubscriptionResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreatePayPalSubscription(
        [FromBody] PayPalCreateSubscriptionRequest request,
        CancellationToken cancellationToken)
    {
        var result = await paymentService.CreatePayPalSubscriptionAsync(
            GetUserId(),
            request,
            cancellationToken);

        return Ok(result);
    }

    [HttpPost("paypal/activate-subscription")]
    [ProducesResponseType(typeof(PayPalActivateSubscriptionResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> ActivatePayPalSubscription(
        [FromBody] PayPalActivateSubscriptionRequest request,
        CancellationToken cancellationToken)
    {
        var result = await paymentService.ActivatePayPalSubscriptionAsync(
            GetUserId(),
            request,
            cancellationToken);

        return Ok(result);
    }

    [HttpPost("mobile/verify-purchase")]
    [ProducesResponseType(typeof(VerifyMobilePurchaseResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> VerifyMobilePurchase(
        [FromBody] VerifyMobilePurchaseRequest request,
        CancellationToken cancellationToken)
    {
        var result = await paymentService.VerifyMobilePurchaseAsync(
            GetUserId(),
            request,
            cancellationToken);

        return Ok(result);
    }

    [HttpGet("ai-credit-packs")]
    [ProducesResponseType(typeof(IReadOnlyList<AiCreditPackDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAiCreditPacks(CancellationToken cancellationToken)
    {
        var packs = await paymentService.GetAiCreditPacksAsync(GetUserId(), cancellationToken);
        return Ok(packs);
    }

    [HttpPost("paypal/create-ai-credit-order")]
    [ProducesResponseType(typeof(PayPalCreateOrderResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreatePayPalAiCreditOrder(
        [FromBody] PayPalCreateAiCreditOrderRequest request,
        CancellationToken cancellationToken)
    {
        var result = await paymentService.CreatePayPalAiCreditOrderAsync(
            GetUserId(),
            request,
            cancellationToken);

        return Ok(result);
    }

    [HttpPost("paypal/capture-ai-credit-order")]
    [ProducesResponseType(typeof(PayPalCaptureAiCreditOrderResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> CapturePayPalAiCreditOrder(
        [FromBody] PayPalCaptureOrderRequest request,
        CancellationToken cancellationToken)
    {
        var result = await paymentService.CapturePayPalAiCreditOrderAsync(
            GetUserId(),
            request,
            cancellationToken);

        return Ok(result);
    }

    [HttpPost("mobile/verify-ai-credit-purchase")]
    [ProducesResponseType(typeof(VerifyMobileAiCreditPurchaseResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> VerifyMobileAiCreditPurchase(
        [FromBody] VerifyMobileAiCreditPurchaseRequest request,
        CancellationToken cancellationToken)
    {
        var result = await paymentService.VerifyMobileAiCreditPurchaseAsync(
            GetUserId(),
            request,
            cancellationToken);

        return Ok(result);
    }
}
