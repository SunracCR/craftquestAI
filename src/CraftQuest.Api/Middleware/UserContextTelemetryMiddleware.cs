using System.Diagnostics;
using System.Security.Claims;

namespace CraftQuest.Api.Middleware;

/// <summary>
/// Enriches the current OpenTelemetry <see cref="Activity"/> with authenticated user context
/// so Application Insights can correlate requests and dependencies per user.
/// </summary>
public sealed class UserContextTelemetryMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context)
    {
        EnrichCurrentActivity(context);
        await next(context);
    }

    private static void EnrichCurrentActivity(HttpContext context)
    {
        if (context.User.Identity?.IsAuthenticated != true)
        {
            return;
        }

        var userId = context.User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? context.User.FindFirstValue("sub");

        if (string.IsNullOrEmpty(userId))
        {
            return;
        }

        var activity = Activity.Current;
        if (activity is null)
        {
            return;
        }

        activity.SetTag("enduser.id", userId);
        activity.SetTag("craftquest.userId", userId);
    }
}
