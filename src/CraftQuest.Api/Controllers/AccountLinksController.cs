using CraftQuest.Api.Services;
using CraftQuest.Application.Options;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace CraftQuest.Api.Controllers;

[ApiController]
public class AccountLinksController(IOptions<JoinLinkOptions> joinLinkOptions) : ControllerBase
{
    [HttpGet("/verify-email/{token}")]
    [AllowAnonymous]
    [Produces("text/html")]
    public IActionResult VerifyEmailLanding(string token)
    {
        return RenderLanding(AccountLinkKind.VerifyEmail, token);
    }

    [HttpGet("/reset-password/{token}")]
    [AllowAnonymous]
    [Produces("text/html")]
    public IActionResult ResetPasswordLanding(string token)
    {
        return RenderLanding(AccountLinkKind.ResetPassword, token);
    }

    [HttpGet("/confirm-password-change/{token}")]
    [AllowAnonymous]
    [Produces("text/html")]
    public IActionResult ConfirmPasswordChangeLanding(string token)
    {
        return RenderLanding(AccountLinkKind.ConfirmPasswordChange, token);
    }

    private IActionResult RenderLanding(AccountLinkKind kind, string token){
        if (string.IsNullOrWhiteSpace(token) || token.Trim().Length < 20)
        {
            return NotFound();
        }

        var device = JoinLandingPageRenderer.DetectDevice(Request.Headers.UserAgent.ToString());
        var html = JoinLandingPageRenderer.RenderAccountLinkLanding(
            joinLinkOptions.Value,
            kind,
            token.Trim(),
            device,
            Request.Headers.AcceptLanguage.ToString());

        return Content(html, "text/html; charset=utf-8");
    }
}
