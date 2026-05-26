using System.Diagnostics;
using System.Text.Json;
using System.Text.Json.Serialization;
using CraftQuest.Application.Exceptions;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Middleware;

public sealed class ExceptionHandlingMiddleware(
    RequestDelegate next,
    ILogger<ExceptionHandlingMiddleware> logger,
    IHostEnvironment environment)
{
    private static readonly JsonSerializerOptions ProblemJsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    };

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (OperationCanceledException) when (context.RequestAborted.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            if (context.Response.HasStarted)
            {
                logger.LogError(
                    ex,
                    "Unhandled exception after the response started for {Method} {Path}",
                    context.Request.Method,
                    context.Request.Path.Value);

                throw;
            }

            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        var (statusCode, title, logLevel, includeException) = MapException(exception);
        LogException(context, exception, statusCode, logLevel, includeException);

        var problem = BuildProblemDetails(context, statusCode, title, exception);

        context.Response.Clear();
        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/problem+json";

        await context.Response.WriteAsJsonAsync(problem, ProblemJsonOptions, context.RequestAborted);
    }

    private static (int StatusCode, string Title, LogLevel Level, bool IncludeException) MapException(
        Exception exception) =>
        exception switch
        {
            AppException app => (
                app.StatusCode,
                app.Message,
                app.StatusCode >= 500 ? LogLevel.Error : LogLevel.Warning,
                app.StatusCode >= 500),
            UnauthorizedAccessException => (
                StatusCodes.Status401Unauthorized,
                "Unauthorized.",
                LogLevel.Warning,
                false),
            _ => (
                StatusCodes.Status500InternalServerError,
                "An unexpected error occurred.",
                LogLevel.Error,
                true),
        };

    private void LogException(
        HttpContext context,
        Exception exception,
        int statusCode,
        LogLevel level,
        bool includeException)
    {
        var method = context.Request.Method;
        var path = context.Request.Path.Value ?? "/";

        if (includeException)
        {
            logger.Log(
                level,
                exception,
                "Request failed with HTTP {StatusCode} for {Method} {Path}",
                statusCode,
                method,
                path);
        }
        else
        {
            logger.Log(
                level,
                exception,
                "Request failed with HTTP {StatusCode} for {Method} {Path}: {Message}",
                statusCode,
                method,
                path,
                exception.Message);
        }
    }

    private ProblemDetails BuildProblemDetails(
        HttpContext context,
        int statusCode,
        string title,
        Exception exception)
    {
        var traceId = Activity.Current?.TraceId.ToString() ?? context.TraceIdentifier;

        var problem = new ProblemDetails
        {
            Status = statusCode,
            Title = title,
            Type = $"https://httpstatuses.io/{statusCode}",
            Instance = context.Request.Path,
        };

        problem.Extensions["traceId"] = traceId;

        if (exception is AppException appException)
        {
            if (!string.IsNullOrWhiteSpace(appException.ErrorCode))
            {
                problem.Extensions["errorCode"] = appException.ErrorCode;
            }

            foreach (var (key, value) in appException.Metadata)
            {
                if (value is not null)
                {
                    problem.Extensions[key] = value;
                }
            }
        }

        if (environment.IsDevelopment()
            && exception is not AppException
            && exception is not UnauthorizedAccessException)
        {
            problem.Detail = exception.Message;
            problem.Extensions["stackTrace"] = exception.StackTrace;
        }

        return problem;
    }
}
