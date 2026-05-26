using System.Security.Claims;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(IAuthService authService) : ApiControllerBase
{
    [HttpPost("register")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> Register(
        [FromBody] RegisterRequest request,
        CancellationToken cancellationToken)
    {
        var result = await authService.RegisterAsync(request, cancellationToken);
        return CreatedAtAction(nameof(Me), result);
    }

    [HttpPost("login")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Login(
        [FromBody] LoginRequest request,
        CancellationToken cancellationToken)
    {
        var result = await authService.LoginAsync(request, cancellationToken);
        return Ok(result);
    }

    [HttpPost("refresh")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(AuthTokensDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Refresh(
        [FromBody] RefreshTokenRequest request,
        CancellationToken cancellationToken)
    {
        var tokens = await authService.RefreshAsync(request, cancellationToken);
        return Ok(tokens);
    }

    [HttpGet("me")]
    [Authorize]
    [ProducesResponseType(typeof(UserProfileDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Me(CancellationToken cancellationToken)
    {
        var profile = await authService.GetProfileAsync(GetUserId(), cancellationToken);
        return Ok(profile);
    }

    [HttpPatch("me")]
    [Authorize]
    [ProducesResponseType(typeof(UserProfileDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateMe(
        [FromBody] UpdateProfileRequest request,
        CancellationToken cancellationToken)
    {
        var profile = await authService.UpdateProfileAsync(
            GetUserId(),
            request,
            cancellationToken);
        return Ok(profile);
    }

    [HttpPost("change-password")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> ChangePassword(
        [FromBody] ChangePasswordRequest request,
        CancellationToken cancellationToken)
    {
        await authService.ChangePasswordAsync(GetUserId(), request, cancellationToken);
        return NoContent();
    }

    [HttpPost("google")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status501NotImplemented)]
    public IActionResult Google() =>
        StatusCode(StatusCodes.Status501NotImplemented, new { message = "Google sign-in is not implemented yet." });

    [HttpPost("apple")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status501NotImplemented)]
    public IActionResult Apple() =>
        StatusCode(StatusCodes.Status501NotImplemented, new { message = "Apple sign-in is not implemented yet." });

}
