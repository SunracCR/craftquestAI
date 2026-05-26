using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Billing;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/billing")]
[Authorize]
public class BillingController(IBillingService billingService) : ApiControllerBase
{
    [HttpGet("me")]
    [ProducesResponseType(typeof(UserBillingDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyBilling(CancellationToken cancellationToken)
    {
        var billing = await billingService.GetMyBillingAsync(GetUserId(), cancellationToken);
        return Ok(billing);
    }

    [HttpPost("cancel")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> CancelSubscription(CancellationToken cancellationToken)
    {
        await billingService.CancelSubscriptionAsync(GetUserId(), cancellationToken);
        return NoContent();
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
