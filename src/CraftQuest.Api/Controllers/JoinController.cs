using System.Text.Json;
using CraftQuest.Api.Services;
using CraftQuest.Application;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Options;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace CraftQuest.Api.Controllers;

[ApiController]
public class JoinController(
    IShareCodeService shareCodeService,
    IOptions<JoinLinkOptions> joinLinkOptions) : ControllerBase
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        WriteIndented = true,
    };

    [HttpGet("/join")]
    [AllowAnonymous]
    [Produces("text/html")]
    public ContentResult JoinLandingGeneric()
    {
        var html = JoinLandingPageRenderer.RenderGenericLanding(
            joinLinkOptions.Value,
            Request.Headers.AcceptLanguage.ToString());

        return Content(html, "text/html; charset=utf-8");
    }

    [HttpGet("/join/{code}")]
    [AllowAnonymous]
    [Produces("text/html")]
    public async Task<IActionResult> JoinLanding(string code, CancellationToken cancellationToken)
    {
        var normalized = code.Trim().ToUpperInvariant();
        if (!JoinLinkUrlBuilder.IsValidCodeFormat(normalized))
        {
            return NotFound();
        }

        var preview = await shareCodeService.GetJoinPreviewAsync(normalized, cancellationToken);
        if (preview is null)
        {
            return NotFound();
        }

        var device = JoinLandingPageRenderer.DetectDevice(Request.Headers.UserAgent.ToString());
        var html = JoinLandingPageRenderer.RenderJoinLanding(
            joinLinkOptions.Value,
            normalized,
            preview,
            device,
            Request.Headers.AcceptLanguage.ToString());

        return Content(html, "text/html; charset=utf-8");
    }

    [HttpGet("/api/join/{code}/preview")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(CraftQuest.Application.Models.Sharing.JoinPreviewDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> JoinPreview(string code, CancellationToken cancellationToken)
    {
        var preview = await shareCodeService.GetJoinPreviewAsync(code, cancellationToken);
        return preview is null ? NotFound() : Ok(preview);
    }

    [HttpGet("/.well-known/assetlinks.json")]
    [AllowAnonymous]
    [Produces("application/json")]
    public IActionResult AndroidAssetLinks()
    {
        var options = joinLinkOptions.Value;
        if (string.IsNullOrWhiteSpace(options.AndroidPackageName)
            || options.AndroidSha256Fingerprints.Count == 0)
        {
            return Ok(Array.Empty<object>());
        }

        var payload = new[]
        {
            new
            {
                relation = new[] { "delegate_permission/common.handle_all_urls" },
                target = new
                {
                    @namespace = "android_app",
                    package_name = options.AndroidPackageName,
                    sha256_cert_fingerprints = options.AndroidSha256Fingerprints,
                },
            },
        };

        return Content(
            JsonSerializer.Serialize(payload, JsonOptions),
            "application/json; charset=utf-8");
    }

    [HttpGet("/.well-known/apple-app-site-association")]
    [AllowAnonymous]
    [Produces("application/json")]
    public IActionResult AppleAppSiteAssociation()
    {
        var options = joinLinkOptions.Value;
        if (options.IosAppIds.Count == 0)
        {
            return Content("{}", "application/json; charset=utf-8");
        }

        var payload = new
        {
            applinks = new
            {
                apps = Array.Empty<string>(),
                details = options.IosAppIds.Select(appId => new
                {
                    appID = appId,
                    paths = new[]
                    {
                        "/join",
                        "/join/*",
                        "/verify-email/*",
                        "/reset-password/*",
                        "/confirm-password-change/*",
                    },
                }).ToArray(),
            },
        };

        return Content(
            JsonSerializer.Serialize(payload, JsonOptions),
            "application/json; charset=utf-8");
    }
}
