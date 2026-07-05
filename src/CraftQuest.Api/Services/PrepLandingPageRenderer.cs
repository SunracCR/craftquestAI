using System.Net;
using CraftQuest.Application;
using CraftQuest.Application.Models.PrepPlus;
using CraftQuest.Application.Options;
using CraftQuest.Api.Services;

namespace CraftQuest.Api.Services;

public static class PrepLandingPageRenderer
{
    public static string Render(
        JoinLinkOptions options,
        PrepReferralLandingPreviewDto preview,
        string? referralCode,
        JoinDeviceKind device,
        string? acceptLanguage)
    {
        var labels = ResolveLabels(acceptLanguage);
        var encodedTitle = WebUtility.HtmlEncode(preview.Title);
        var encodedCategory = WebUtility.HtmlEncode(preview.CategoryName);
        var encodedDescription = WebUtility.HtmlEncode(preview.Description ?? labels.DefaultDescription);
        var deepLink = PrepReferralLinkUrlBuilder.BuildDeepLink(preview.Slug, referralCode);
        var webUrl = PrepReferralLinkUrlBuilder.BuildWebUrl(options, preview.Slug, referralCode);
        var shareUrl = PrepReferralLinkUrlBuilder.BuildShareUrl(options, preview.Slug, referralCode ?? string.Empty);
        var priceBlock = preview.LowestPaidPrice.HasValue
            ? $"""<p class="price">{WebUtility.HtmlEncode(FormatPrice(preview.LowestPaidPrice.Value, preview.CurrencyCode))}</p>"""
            : string.Empty;

        var storeUrl = device switch
        {
            JoinDeviceKind.Android => options.PlayStoreUrl,
            JoinDeviceKind.Ios => options.AppStoreUrl,
            _ => webUrl,
        };

        var storeButton = device switch
        {
            JoinDeviceKind.Android =>
                $"""<a class="btn store" href="{WebUtility.HtmlEncode(storeUrl)}">{WebUtility.HtmlEncode(labels.GetAndroid)}</a>""",
            JoinDeviceKind.Ios =>
                $"""<a class="btn store" href="{WebUtility.HtmlEncode(storeUrl)}">{WebUtility.HtmlEncode(labels.GetIos)}</a>""",
            _ => string.Empty,
        };

        var mobileScript = device is JoinDeviceKind.Android or JoinDeviceKind.Ios
            ? $"<script>(function(){{var d='{deepLink}';window.location.href=d;setTimeout(function(){{document.body.classList.add('show-fallback');}},1200);}})();</script>"
            : string.Empty;

        var ogUrl = string.IsNullOrWhiteSpace(referralCode)
            ? PrepReferralLinkUrlBuilder.BuildPublicLandingUrl(options, preview.Slug)
            : shareUrl;

        var ogImageUrl = ResolveOgImageUrl(options, preview);
        var encodedOgImageUrl = WebUtility.HtmlEncode(ogImageUrl);
        var brandIconUrl = WebUtility.HtmlEncode(PrepReferralLinkUrlBuilder.ResolveBrandIconUrl(options));
        var faviconUrl = WebUtility.HtmlEncode(PrepReferralLinkUrlBuilder.ResolveFaviconUrl(options));
        var ogImageType = WebUtility.HtmlEncode(
            string.IsNullOrWhiteSpace(preview.CoverContentType)
                ? "image/jpeg"
                : preview.CoverContentType);
        var ogImageTags = $"""
              <meta property="og:image" content="{encodedOgImageUrl}" />
              <meta property="og:image:secure_url" content="{encodedOgImageUrl}" />
              <meta property="og:image:type" content="{ogImageType}" />
              <meta property="og:image:alt" content="{encodedTitle}" />
              <meta name="twitter:image" content="{encodedOgImageUrl}" />
              <link rel="image_src" href="{encodedOgImageUrl}" />
              """;

        var coverBlock = string.IsNullOrWhiteSpace(preview.CoverMediaUrl)
            ? string.Empty
            : $"""<img class="cover" src="{WebUtility.HtmlEncode(preview.CoverMediaUrl)}" alt="{encodedTitle}" />""";

        var body = $"""
            <main class="card">
              {coverBlock}
              <div class="brand-row">
                <img class="brand-icon" src="{brandIconUrl}" alt="CraftQuestAI" width="32" height="32" />
                <p class="brand">CraftQuestAI · Preparación+</p>
              </div>
              <p class="eyebrow">{WebUtility.HtmlEncode(labels.PrepPlusLabel)}</p>
              <h1>{encodedTitle}</h1>
              <p class="subtitle">{encodedCategory}</p>
              {priceBlock}
              <p class="description">{encodedDescription}</p>
              <div class="actions">
                <a class="btn primary" href="{WebUtility.HtmlEncode(webUrl)}">{WebUtility.HtmlEncode(labels.ContinueWeb)}</a>
                {storeButton}
              </div>
            </main>
            {mobileScript}
            """;

        return $"""
            <!DOCTYPE html>
            <html lang="{labels.Lang}">
            <head>
              <meta charset="utf-8" />
              <meta name="viewport" content="width=device-width, initial-scale=1" />
              <title>{encodedTitle} · CraftQuestAI</title>
              <link rel="icon" type="image/png" sizes="32x32" href="{faviconUrl}" />
              <link rel="apple-touch-icon" href="{brandIconUrl}" />
              <meta property="og:site_name" content="CraftQuestAI" />
              <meta property="og:title" content="{encodedTitle}" />
              <meta property="og:description" content="{encodedDescription}" />
              <meta property="og:url" content="{WebUtility.HtmlEncode(ogUrl)}" />
              <meta property="og:type" content="website" />
              <meta name="twitter:card" content="summary_large_image" />
              {ogImageTags}
              {LandingStyles}
            </head>
            <body>
              {body}
            </body>
            </html>
            """;
    }

    private const string LandingStyles = """
              <style>
                :root {
                  --bg: #0f1c20;
                  --card: #162830;
                  --text: #fdfdfd;
                  --muted: #a9b7c0;
                  --accent: #4ecdc4;
                }
                * { box-sizing: border-box; }
                body {
                  margin: 0;
                  min-height: 100vh;
                  font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
                  background: radial-gradient(circle at top, #1a3340, var(--bg));
                  color: var(--text);
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  padding: 24px;
                }
                .card {
                  width: min(480px, 100%);
                  background: var(--card);
                  border-radius: 20px;
                  padding: 28px 24px;
                  box-shadow: 0 18px 50px rgba(0,0,0,0.35);
                }
                .cover {
                  display: block;
                  width: 100%;
                  max-height: 220px;
                  object-fit: cover;
                  border-radius: 14px;
                  margin: 0 0 18px;
                }
                .brand-row {
                  display: flex;
                  align-items: center;
                  gap: 10px;
                  margin: 0 0 8px;
                }
                .brand-icon {
                  width: 32px;
                  height: 32px;
                  border-radius: 8px;
                  flex-shrink: 0;
                }
                .brand { color: var(--accent); font-size: 0.85rem; margin: 0; }
                .eyebrow { color: var(--muted); font-size: 0.8rem; margin: 0 0 6px; text-transform: uppercase; letter-spacing: 0.06em; }
                h1 { margin: 0 0 8px; font-size: 1.6rem; line-height: 1.2; }
                .subtitle { margin: 0 0 12px; color: var(--muted); }
                .price { margin: 0 0 12px; font-size: 1.1rem; font-weight: 700; color: var(--accent); }
                .description { margin: 0 0 20px; color: var(--muted); line-height: 1.5; }
                .actions { display: flex; flex-direction: column; gap: 10px; }
                .btn {
                  display: block; width: 100%; text-align: center; text-decoration: none;
                  border-radius: 12px; padding: 13px 16px; font-size: 0.95rem; font-weight: 600;
                }
                .btn.primary { background: var(--accent); color: #0f1c20; }
                .btn.store { background: transparent; color: var(--text); border: 1px solid rgba(253,253,253,0.25); }
              </style>
              """;

    private static string FormatPrice(decimal amount, string? currencyCode) =>
        $"{currencyCode ?? "USD"} {amount:0.##}";

    private static string ResolveOgImageUrl(
        JoinLinkOptions options,
        PrepReferralLandingPreviewDto preview)
    {
        if (!string.IsNullOrWhiteSpace(preview.CoverMediaUrl))
        {
            return preview.CoverMediaUrl;
        }

        if (!string.IsNullOrWhiteSpace(options.DefaultOgImageUrl))
        {
            return options.DefaultOgImageUrl.Trim();
        }

        return $"{options.WebAppUrl.TrimEnd('/')}/icons/Icon-512.png";
    }

    private static PrepLabels ResolveLabels(string? acceptLanguage)
    {
        var lang = acceptLanguage?.Split(',').FirstOrDefault()?.Trim().ToLowerInvariant() ?? "es";
        if (lang.StartsWith("en", StringComparison.Ordinal))
        {
            return new PrepLabels(
                Lang: "en",
                PrepPlusLabel: "Prep+",
                DefaultDescription: "Practice with curated quizzes on CraftQuestAI.",
                ContinueWeb: "Continue on web",
                GetAndroid: "Get on Google Play",
                GetIos: "Get on App Store");
        }

        if (lang.StartsWith("pt", StringComparison.Ordinal))
        {
            return new PrepLabels(
                Lang: "pt",
                PrepPlusLabel: "Prep+",
                DefaultDescription: "Pratique com questionarios curados no CraftQuestAI.",
                ContinueWeb: "Continuar na web",
                GetAndroid: "Baixar no Google Play",
                GetIos: "Baixar na App Store");
        }

        return new PrepLabels(
            Lang: "es",
            PrepPlusLabel: "Preparación+",
            DefaultDescription: "Practica con cuestionarios curados en CraftQuestAI.",
            ContinueWeb: "Continuar en la web",
            GetAndroid: "Descargar en Google Play",
            GetIos: "Descargar en App Store");
    }

    private sealed record PrepLabels(
        string Lang,
        string PrepPlusLabel,
        string DefaultDescription,
        string ContinueWeb,
        string GetAndroid,
        string GetIos);
}
