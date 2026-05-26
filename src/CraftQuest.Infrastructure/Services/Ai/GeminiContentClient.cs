using System.Net.Http.Json;
using System.Text.Json;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Options;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Ai;

public sealed class GeminiContentClient(
    IHttpClientFactory httpClientFactory,
    IOptions<AiOptions> options)
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    public async Task<GeminiTextResult> GenerateTextAsync(
        string prompt,
        object generationConfig,
        string operationName,
        CancellationToken cancellationToken = default)
    {
        var models = GeminiModelResolver.GetModelsToTry(options.Value);
        if (models.Count == 0)
        {
            throw new AppException("No Gemini models configured.", 503, "AI_NOT_CONFIGURED");
        }

        Exception? last = null;
        foreach (var model in models)
        {
            try
            {
                var text = await PostTextAsync(
                    model,
                    prompt,
                    generationConfig,
                    operationName,
                    cancellationToken);
                return new GeminiTextResult(text, model);
            }
            catch (AppException ex) when (GeminiApiErrorHandler.IsModelFallbackEligible(ex) && model != models[^1])
            {
                last = ex;
            }
        }

        throw last ?? new AppException($"{operationName} failed.", 502);
    }

    public Task<string> GenerateTextWithModelAsync(
        string model,
        string prompt,
        object generationConfig,
        string operationName,
        CancellationToken cancellationToken = default) =>
        PostTextAsync(model, prompt, generationConfig, operationName, cancellationToken);

    private async Task<string> PostTextAsync(
        string model,
        string prompt,
        object generationConfig,
        string operationName,
        CancellationToken cancellationToken)
    {
        var aiOptions = options.Value;
        if (string.IsNullOrWhiteSpace(aiOptions.GeminiApiKey))
        {
            throw new AppException("Gemini API key is not configured.", 503, "AI_NOT_CONFIGURED");
        }

        var url =
            $"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={aiOptions.GeminiApiKey}";
        var client = httpClientFactory.CreateClient("Gemini");

        using var response = await client.PostAsJsonAsync(
            url,
            new
            {
                contents = new[]
                {
                    new { parts = new[] { new { text = prompt } } },
                },
                generationConfig = generationConfig,
            },
            cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync(cancellationToken);
            GeminiApiErrorHandler.ThrowIfFailed(response, errorBody, operationName);
        }

        var payload = await response.Content.ReadFromJsonAsync<GeminiResponse>(JsonOptions, cancellationToken)
            ?? throw new AppException("Gemini returned an empty response.", 502);

        var text = payload.Candidates?
            .FirstOrDefault()?
            .Content?
            .Parts?
            .FirstOrDefault()?
            .Text;

        if (string.IsNullOrWhiteSpace(text))
        {
            throw new AppException("Gemini did not return text content.", 502);
        }

        return text;
    }

    public async Task<string> PostJsonPayloadAsync(
        string model,
        object requestBody,
        string operationName,
        CancellationToken cancellationToken)
    {
        var aiOptions = options.Value;
        if (string.IsNullOrWhiteSpace(aiOptions.GeminiApiKey))
        {
            throw new AppException("Gemini API key is not configured.", 503, "AI_NOT_CONFIGURED");
        }

        var url =
            $"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={aiOptions.GeminiApiKey}";
        var client = httpClientFactory.CreateClient("Gemini");

        using var response = await client.PostAsJsonAsync(url, requestBody, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync(cancellationToken);
            GeminiApiErrorHandler.ThrowIfFailed(response, errorBody, operationName);
        }

        var payload = await response.Content.ReadFromJsonAsync<GeminiResponse>(JsonOptions, cancellationToken)
            ?? throw new AppException("Gemini returned an empty response.", 502);

        return payload.Candidates?
            .FirstOrDefault()?
            .Content?
            .Parts?
            .FirstOrDefault()?
            .Text?
            .Trim()
            ?? string.Empty;
    }

    public async Task<string> GenerateFromPayloadWithFallbackAsync(
        object requestBody,
        string operationName,
        CancellationToken cancellationToken)
    {
        var models = GeminiModelResolver.GetModelsToTry(options.Value);
        Exception? last = null;

        foreach (var model in models)
        {
            try
            {
                return await PostJsonPayloadAsync(model, requestBody, operationName, cancellationToken);
            }
            catch (AppException ex) when (GeminiApiErrorHandler.IsModelFallbackEligible(ex) && model != models[^1])
            {
                last = ex;
            }
        }

        throw last ?? new AppException($"{operationName} failed.", 502);
    }

    private sealed class GeminiResponse
    {
        public List<GeminiCandidate>? Candidates { get; set; }
    }

    private sealed class GeminiCandidate
    {
        public GeminiContent? Content { get; set; }
    }

    private sealed class GeminiContent
    {
        public List<GeminiPart>? Parts { get; set; }
    }

    private sealed class GeminiPart
    {
        public string? Text { get; set; }
    }
}

public readonly record struct GeminiTextResult(string Text, string Model);

internal static class GeminiModelResolver
{
    public static IReadOnlyList<string> GetModelsToTry(AiOptions options)
    {
        var models = new List<string>();
        if (!string.IsNullOrWhiteSpace(options.GeminiModel))
        {
            models.Add(options.GeminiModel.Trim());
        }

        foreach (var fallback in options.GeminiFallbackModels)
        {
            if (!string.IsNullOrWhiteSpace(fallback))
            {
                models.Add(fallback.Trim());
            }
        }

        return models
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }
}
