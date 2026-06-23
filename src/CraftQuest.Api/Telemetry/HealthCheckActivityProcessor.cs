using System.Diagnostics;
using OpenTelemetry;

namespace CraftQuest.Api.Telemetry;

/// <summary>
/// Evita exportar trazas de health checks y del endpoint raíz (probes de Azure).
/// </summary>
public sealed class HealthCheckActivityProcessor : BaseProcessor<Activity>
{
    public override void OnEnd(Activity activity)
    {
        if (ShouldDrop(activity))
        {
            activity.ActivityTraceFlags &= ~ActivityTraceFlags.Recorded;
        }
    }

    private static bool ShouldDrop(Activity activity)
    {
        if (activity.GetTagItem("url.path") is string path && IsNoisePath(path))
        {
            return true;
        }

        if (activity.GetTagItem("http.route") is string route && IsNoisePath(route))
        {
            return true;
        }

        return activity.DisplayName.Contains("/health", StringComparison.OrdinalIgnoreCase)
            || activity.DisplayName.Equals("GET /", StringComparison.OrdinalIgnoreCase);
    }

    private static bool IsNoisePath(string path) =>
        path.Equals("/", StringComparison.OrdinalIgnoreCase)
        || path.StartsWith("/health", StringComparison.OrdinalIgnoreCase);
}
