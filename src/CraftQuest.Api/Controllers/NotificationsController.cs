using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Notifications;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/notifications")]
[Authorize]
public class NotificationsController(INotificationService notificationService) : ApiControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(NotificationListResultDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> List(
        [FromQuery] string? cursor,
        [FromQuery] int limit = 30,
        [FromQuery] bool unreadOnly = false,
        CancellationToken cancellationToken = default)
    {
        var result = await notificationService.ListAsync(
            GetUserId(),
            cursor,
            limit,
            unreadOnly,
            cancellationToken);
        return Ok(result);
    }

    [HttpGet("unread-count")]
    [ProducesResponseType(typeof(UnreadCountDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetUnreadCount(CancellationToken cancellationToken = default)
    {
        var count = await notificationService.CountUnreadAsync(GetUserId(), cancellationToken);
        return Ok(new UnreadCountDto { Count = count });
    }

    [HttpPost("{notificationId:guid}/read")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> MarkRead(
        Guid notificationId,
        CancellationToken cancellationToken = default)
    {
        await notificationService.MarkReadAsync(GetUserId(), notificationId, cancellationToken);
        return NoContent();
    }

    [HttpPost("read-all")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> MarkAllRead(CancellationToken cancellationToken = default)
    {
        await notificationService.MarkAllReadAsync(GetUserId(), cancellationToken);
        return NoContent();
    }

    [HttpPost("device-tokens")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> RegisterDeviceToken(
        [FromBody] RegisterDeviceTokenRequest request,
        CancellationToken cancellationToken = default)
    {
        await notificationService.RegisterDeviceTokenAsync(GetUserId(), request, cancellationToken);
        return NoContent();
    }

    [HttpDelete("device-tokens")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> RemoveDeviceToken(
        [FromQuery] string token,
        CancellationToken cancellationToken = default)
    {
        await notificationService.RemoveDeviceTokenAsync(GetUserId(), token, cancellationToken);
        return NoContent();
    }

    [HttpGet("preferences")]
    [ProducesResponseType(typeof(NotificationPreferencesDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPreferences(CancellationToken cancellationToken = default)
    {
        var prefs = await notificationService.GetPreferencesAsync(GetUserId(), cancellationToken);
        return Ok(prefs);
    }

    [HttpPut("preferences")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> UpdatePreferences(
        [FromBody] UpdateNotificationPreferencesRequest request,
        CancellationToken cancellationToken = default)
    {
        await notificationService.UpdatePreferencesAsync(GetUserId(), request, cancellationToken);
        return NoContent();
    }
}
