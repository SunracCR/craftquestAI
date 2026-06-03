using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Billing;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/billing")]
[Authorize]
public class BillingController(
    IBillingService billingService,
    IPaymentService paymentService) : ApiControllerBase
{
    [HttpGet("me")]
    [ProducesResponseType(typeof(UserBillingDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyBilling(CancellationToken cancellationToken)
    {
        var billing = await billingService.GetMyBillingAsync(GetUserId(), cancellationToken);
        return Ok(billing);
    }

    [HttpGet("purchases")]
    [ProducesResponseType(typeof(IReadOnlyList<PurchaseHistoryItemDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyPurchases(CancellationToken cancellationToken)
    {
        var purchases = await billingService.GetMyPurchasesAsync(GetUserId(), cancellationToken);
        return Ok(purchases);
    }

    [HttpPost("cancel")]
    [ProducesResponseType(typeof(CancelAutoRenewResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> CancelSubscription(CancellationToken cancellationToken)
    {
        var result = await billingService.CancelAutoRenewAsync(GetUserId(), cancellationToken);
        await paymentService.RevokeProviderAutoRenewAsync(GetUserId(), cancellationToken);
        return Ok(result);
    }

    [HttpPost("cancel-auto-renew")]
    [ProducesResponseType(typeof(CancelAutoRenewResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> CancelAutoRenew(CancellationToken cancellationToken)
    {
        var result = await billingService.CancelAutoRenewAsync(GetUserId(), cancellationToken);
        await paymentService.RevokeProviderAutoRenewAsync(GetUserId(), cancellationToken);
        return Ok(result);
    }

    [HttpPost("resume-auto-renew")]
    [ProducesResponseType(typeof(ReactivateAutoRenewResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> ResumeAutoRenew(CancellationToken cancellationToken)
    {
        var restore = await paymentService.TryRestoreProviderAutoRenewAsync(GetUserId(), cancellationToken);
        if (restore.RequiresResubscribe)
        {
            return Ok(new ReactivateAutoRenewResponse
            {
                AutoRenewEnabled = false,
                ProviderCode = restore.ProviderCode,
                RequiresResubscribe = true,
                ManageInStore = false,
            });
        }

        var result = await billingService.ReactivateAutoRenewAsync(GetUserId(), cancellationToken);
        return Ok(result);
    }

    [HttpGet("expiring")]
    [ProducesResponseType(typeof(bool), StatusCodes.Status200OK)]
    public async Task<IActionResult> IsSubscriptionExpiring(
        [FromQuery] int withinDays = 7,
        CancellationToken cancellationToken = default)
    {
        var expiring = await billingService.IsSubscriptionExpiringAsync(
            GetUserId(), withinDays, cancellationToken);
        return Ok(expiring);
    }
}
