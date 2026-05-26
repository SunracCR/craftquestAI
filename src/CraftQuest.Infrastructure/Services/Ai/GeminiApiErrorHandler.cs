using System.Net;
using CraftQuest.Application.Exceptions;

namespace CraftQuest.Infrastructure.Services.Ai;

internal static class GeminiApiErrorHandler
{
    public static void ThrowIfFailed(
        HttpResponseMessage response,
        string errorBody,
        string operationName)
    {
        if (response.IsSuccessStatusCode)
        {
            return;
        }

        if (IsQuotaExhausted(response.StatusCode, errorBody))
        {
            throw new AppException(
                "Gemini API quota is exhausted. Add credits in Google AI Studio (ai.google.dev).",
                502,
                "AI_GEMINI_QUOTA_EXHAUSTED");
        }

        if (IsModelUnavailable(response.StatusCode, errorBody))
        {
            throw new AppException(
                "The configured Gemini model is unavailable. Set Ai:GeminiModel to gemini-2.5-flash (or newer) and restart the API.",
                502,
                "AI_GEMINI_MODEL_UNAVAILABLE");
        }

        if (IsOverloaded(response.StatusCode, errorBody))
        {
            throw new AppException(
                "Gemini is temporarily overloaded due to high demand. Please try again in a few minutes.",
                503,
                "AI_GEMINI_OVERLOADED");
        }

        var snippet = errorBody.Length > 500 ? errorBody[..500] + "…" : errorBody;
        throw new AppException($"{operationName} failed: {snippet}", 502);
    }

    private static bool IsQuotaExhausted(HttpStatusCode statusCode, string errorBody) =>
        statusCode == HttpStatusCode.TooManyRequests
        || errorBody.Contains("RESOURCE_EXHAUSTED", StringComparison.OrdinalIgnoreCase)
        || errorBody.Contains("prepayment credits", StringComparison.OrdinalIgnoreCase)
        || errorBody.Contains("\"code\": 429", StringComparison.OrdinalIgnoreCase);

    private static bool IsModelUnavailable(HttpStatusCode statusCode, string errorBody) =>
        statusCode == HttpStatusCode.NotFound
        || errorBody.Contains("no longer available", StringComparison.OrdinalIgnoreCase)
        || errorBody.Contains("\"status\": \"NOT_FOUND\"", StringComparison.OrdinalIgnoreCase)
        || errorBody.Contains("is not found for API version", StringComparison.OrdinalIgnoreCase);

    private static bool IsOverloaded(HttpStatusCode statusCode, string errorBody) =>
        statusCode == HttpStatusCode.ServiceUnavailable
        || errorBody.Contains("\"status\": \"UNAVAILABLE\"", StringComparison.OrdinalIgnoreCase)
        || errorBody.Contains("high demand", StringComparison.OrdinalIgnoreCase)
        || errorBody.Contains("\"code\": 503", StringComparison.OrdinalIgnoreCase);

    public static bool IsRetryable(Exception exception) =>
        exception is AppException { ErrorCode: "AI_GEMINI_OVERLOADED" };

    public static bool IsModelFallbackEligible(AppException exception) =>
        exception.ErrorCode is "AI_GEMINI_OVERLOADED" or "AI_GEMINI_MODEL_UNAVAILABLE";

    public static bool IsDeferredRetryEligible(string? errorCode) =>
        errorCode is "AI_GEMINI_OVERLOADED";

    public static TimeSpan GetRetryDelay(int failedAttempt) =>
        failedAttempt switch
        {
            1 => TimeSpan.FromSeconds(3),
            2 => TimeSpan.FromSeconds(8),
            _ => TimeSpan.FromSeconds(15),
        };
}
