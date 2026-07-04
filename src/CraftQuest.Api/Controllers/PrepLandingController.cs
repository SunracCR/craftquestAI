using System.Net;
using System.Text;
using CraftQuest.Application;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Options;
using CraftQuest.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace CraftQuest.Api.Controllers;

[ApiController]
public class PrepLandingController(
    IPrepReferralService prepReferralService,
    IOptions<JoinLinkOptions> joinLinkOptions) : ControllerBase
{
    [HttpGet("/prep/{slug}")]
    [AllowAnonymous]
    [Produces("text/html")]
    public async Task<IActionResult> PrepLanding(
        string slug,
        [FromQuery(Name = "ref")] string? referralCode,
        CancellationToken cancellationToken)
    {
        var normalizedSlug = slug.Trim().ToLowerInvariant();
        var preview = await prepReferralService.GetLandingPreviewAsync(normalizedSlug, cancellationToken);
        if (preview is null)
        {
            return NotFound();
        }

        var normalizedReferral = referralCode?.Trim().ToUpperInvariant();
        if (!string.IsNullOrWhiteSpace(normalizedReferral)
            && !PrepReferralLinkUrlBuilder.IsValidCodeFormat(normalizedReferral))
        {
            normalizedReferral = null;
        }

        var device = JoinLandingPageRenderer.DetectDevice(Request.Headers.UserAgent.ToString());
        var html = PrepLandingPageRenderer.Render(
            joinLinkOptions.Value,
            preview,
            normalizedReferral,
            device,
            Request.Headers.AcceptLanguage.ToString());

        return Content(html, "text/html; charset=utf-8");
    }
}
