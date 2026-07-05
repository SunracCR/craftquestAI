using System.Net;
using System.Text;
using CraftQuest.Application;
using CraftQuest.Application.Models.Sharing;
using CraftQuest.Application.Options;

namespace CraftQuest.Api.Services;

public enum AccountLinkKind
{
    VerifyEmail,
    ResetPassword,
    ConfirmPasswordChange,
    ParentalConsent,
}

public enum JoinDeviceKind
{
    Android,
    Ios,
    Desktop,
}

public static class JoinLandingPageRenderer
{
    public static JoinDeviceKind DetectDevice(string? userAgent)
    {
        if (string.IsNullOrWhiteSpace(userAgent))
        {
            return JoinDeviceKind.Desktop;
        }

        if (userAgent.Contains("Android", StringComparison.OrdinalIgnoreCase))
        {
            return JoinDeviceKind.Android;
        }

        if (userAgent.Contains("iPhone", StringComparison.OrdinalIgnoreCase)
            || userAgent.Contains("iPad", StringComparison.OrdinalIgnoreCase)
            || userAgent.Contains("iPod", StringComparison.OrdinalIgnoreCase))
        {
            return JoinDeviceKind.Ios;
        }

        return JoinDeviceKind.Desktop;
    }

    public static bool IsSocialPreviewCrawler(string? userAgent)
    {
        if (string.IsNullOrWhiteSpace(userAgent))
        {
            return false;
        }

        return userAgent.Contains("facebookexternalhit", StringComparison.OrdinalIgnoreCase)
            || userAgent.Contains("Facebot", StringComparison.OrdinalIgnoreCase)
            || userAgent.Contains("Twitterbot", StringComparison.OrdinalIgnoreCase)
            || userAgent.Contains("LinkedInBot", StringComparison.OrdinalIgnoreCase)
            || userAgent.Contains("WhatsApp", StringComparison.OrdinalIgnoreCase)
            || userAgent.Contains("Slackbot", StringComparison.OrdinalIgnoreCase)
            || userAgent.Contains("TelegramBot", StringComparison.OrdinalIgnoreCase)
            || userAgent.Contains("Discordbot", StringComparison.OrdinalIgnoreCase);
    }

    public static string RenderGenericLanding(JoinLinkOptions options, string? acceptLanguage)
    {
        var labels = ResolveLabels(acceptLanguage);
        var webUrl = options.WebAppUrl.TrimEnd('/');

        return BuildDocument(
            title: labels.PageTitle,
            body: $"""
                <main class="card">
                  <p class="brand">CraftQuestAI</p>
                  <h1>{WebUtility.HtmlEncode(labels.EnterCodeTitle)}</h1>
                  <p class="subtitle">{WebUtility.HtmlEncode(labels.EnterCodeSubtitle)}</p>
                  <form class="code-form" action="{WebUtility.HtmlEncode(webUrl)}/join" method="get">
                    <input type="text" name="code" placeholder="CQ-000000" maxlength="9" required />
                    <button type="submit" class="btn primary">{WebUtility.HtmlEncode(labels.ContinueWeb)}</button>
                  </form>
                </main>
                """,
            labels: labels);
    }

    public static string RenderJoinLanding(
        JoinLinkOptions options,
        string code,
        JoinPreviewDto? preview,
        JoinDeviceKind device,
        string? acceptLanguage)
    {
        var labels = ResolveLabels(acceptLanguage);
        var encodedCode = WebUtility.HtmlEncode(code);
        var deepLink = $"craftquest://join/{encodedCode}";
        var webJoinUrl = JoinLinkUrlBuilder.BuildWebJoinUrl(options, code);
        var storeUrl = device switch
        {
            JoinDeviceKind.Android => options.PlayStoreUrl,
            JoinDeviceKind.Ios => options.AppStoreUrl,
            _ => webJoinUrl,
        };

        var quizTitle = preview?.QuizTitle;
        var titleBlock = string.IsNullOrWhiteSpace(quizTitle)
            ? $"""<h1>{WebUtility.HtmlEncode(labels.JoinTitle)}</h1>"""
            : $"""
                <p class="eyebrow">{WebUtility.HtmlEncode(labels.JoinTitle)}</p>
                <h1>{WebUtility.HtmlEncode(quizTitle)}</h1>
                """;

        var policyHint = preview?.AccessPolicy switch
        {
            "group_only" => labels.GroupOnlyHint,
            "guest_open" => labels.GuestOpenHint,
            _ => labels.OpenHint,
        };

        var storeButton = device switch
        {
            JoinDeviceKind.Android => $"""
                <a class="btn store" href="{WebUtility.HtmlEncode(storeUrl)}">{WebUtility.HtmlEncode(labels.GetAndroid)}</a>
                """,
            JoinDeviceKind.Ios => $"""
                <a class="btn store" href="{WebUtility.HtmlEncode(storeUrl)}">{WebUtility.HtmlEncode(labels.GetIos)}</a>
                """,
            _ => string.Empty,
        };

        var mobileScript = device is JoinDeviceKind.Android or JoinDeviceKind.Ios
            ? $"<script>(function(){{var d='{deepLink}';window.location.href=d;setTimeout(function(){{document.body.classList.add('show-fallback');}},1200);}})();</script>"
            : string.Empty;

        const string copyScript = """
            <script>
              function copyCode() {
                var code = document.getElementById("share-code").textContent;
                if (navigator.clipboard) {
                  navigator.clipboard.writeText(code);
                }
              }
            </script>
            """;

        var body = $"""
            <main class="card">
              <p class="brand">CraftQuestAI</p>
              {titleBlock}
              <p class="subtitle">{WebUtility.HtmlEncode(policyHint)}</p>
              <div class="code-box">
                <span class="code-label">{WebUtility.HtmlEncode(labels.CodeLabel)}</span>
                <span class="code-value" id="share-code">{encodedCode}</span>
                <button type="button" class="btn ghost" onclick="copyCode()">{WebUtility.HtmlEncode(labels.CopyCode)}</button>
              </div>
              <div class="actions">
                {storeButton}
                <a class="btn primary" href="{WebUtility.HtmlEncode(webJoinUrl)}">{WebUtility.HtmlEncode(labels.ContinueWeb)}</a>
              </div>
              <p class="footer-note">{WebUtility.HtmlEncode(labels.FooterNote)} · www.CraftQuestAI.com</p>
            </main>
            {mobileScript}
            {copyScript}
            """;

        return BuildDocument(
            title: $"{labels.JoinTitle} · CraftQuestAI",
            body: body,
            labels: labels,
            initialShowFallback: device == JoinDeviceKind.Desktop);
    }

    public static string RenderAccountLinkLanding(
        JoinLinkOptions options,
        AccountLinkKind kind,
        string token,
        JoinDeviceKind device,
        string? acceptLanguage)
    {
        var labels = ResolveAccountLinkLabels(acceptLanguage, kind);
        var action = kind switch
        {
            AccountLinkKind.VerifyEmail => AccountLinkUrlBuilder.VerifyEmail,
            AccountLinkKind.ResetPassword => AccountLinkUrlBuilder.ResetPassword,
            AccountLinkKind.ParentalConsent => AccountLinkUrlBuilder.ParentalConsent,
            _ => AccountLinkUrlBuilder.ConfirmPasswordChange,
        };

        var encodedToken = WebUtility.HtmlEncode(token);
        var deepLink = AccountLinkUrlBuilder.BuildDeepLink(action, token);
        var webUrl = AccountLinkUrlBuilder.BuildWebUrl(options, action, token);
        var storeUrl = device switch
        {
            JoinDeviceKind.Android => options.PlayStoreUrl,
            JoinDeviceKind.Ios => options.AppStoreUrl,
            _ => webUrl,
        };

        var storeButton = device switch
        {
            JoinDeviceKind.Android => $"""
                <a class="btn store" href="{WebUtility.HtmlEncode(storeUrl)}">{WebUtility.HtmlEncode(labels.GetAndroid)}</a>
                """,
            JoinDeviceKind.Ios => $"""
                <a class="btn store" href="{WebUtility.HtmlEncode(storeUrl)}">{WebUtility.HtmlEncode(labels.GetIos)}</a>
                """,
            _ => string.Empty,
        };

        var mobileScript = device is JoinDeviceKind.Android or JoinDeviceKind.Ios
            ? $"<script>(function(){{var d='{WebUtility.HtmlEncode(deepLink)}';window.location.href=d;setTimeout(function(){{document.body.classList.add('show-fallback');}},1200);}})();</script>"
            : string.Empty;

        var body = $"""
            <main class="card">
              <p class="brand">CraftQuestAI</p>
              <h1>{WebUtility.HtmlEncode(labels.Title)}</h1>
              <p class="subtitle">{WebUtility.HtmlEncode(labels.Subtitle)}</p>
              <div class="actions">
                {storeButton}
                <a class="btn primary" href="{WebUtility.HtmlEncode(webUrl)}">{WebUtility.HtmlEncode(labels.ContinueWeb)}</a>
              </div>
              <p class="footer-note">{WebUtility.HtmlEncode(labels.FooterNote)} · www.CraftQuestAI.com</p>
            </main>
            {mobileScript}
            """;

        return BuildDocument(
            title: $"{labels.Title} · CraftQuestAI",
            body: body,
            labels: new LandingLabels(
                Lang: labels.Lang,
                PageTitle: labels.Title,
                JoinTitle: labels.Title,
                EnterCodeTitle: labels.Title,
                EnterCodeSubtitle: labels.Subtitle,
                CodeLabel: string.Empty,
                CopyCode: string.Empty,
                ContinueWeb: labels.ContinueWeb,
                GetAndroid: labels.GetAndroid,
                GetIos: labels.GetIos,
                GuestOpenHint: labels.Subtitle,
                GroupOnlyHint: labels.Subtitle,
                OpenHint: labels.Subtitle,
                FooterNote: labels.FooterNote),
            initialShowFallback: device == JoinDeviceKind.Desktop);
    }

    private static AccountLinkLabels ResolveAccountLinkLabels(string? acceptLanguage, AccountLinkKind kind)
    {
        var lang = acceptLanguage?.Split(',').FirstOrDefault()?.Trim().ToLowerInvariant() ?? "es";
        var isEn = lang.StartsWith("en", StringComparison.Ordinal);
        var isPt = lang.StartsWith("pt", StringComparison.Ordinal);

        return kind switch
        {
            AccountLinkKind.VerifyEmail when isEn => new AccountLinkLabels(
                "en", "Activate your account",
                "Open the app or continue in the browser to verify your email.",
                "Continue on web", "Get on Google Play", "Get on App Store",
                "CraftQuestAI account activation"),
            AccountLinkKind.VerifyEmail when isPt => new AccountLinkLabels(
                "pt", "Ative sua conta",
                "Abra o app ou continue no navegador para verificar seu e-mail.",
                "Continuar na web", "Baixar no Google Play", "Baixar na App Store",
                "Ativacao de conta CraftQuestAI"),
            AccountLinkKind.VerifyEmail => new AccountLinkLabels(
                "es", "Activa tu cuenta",
                "Abre la app o continua en el navegador para verificar tu correo.",
                "Continuar en la web", "Descargar en Google Play", "Descargar en App Store",
                "Activacion de cuenta CraftQuestAI"),
            AccountLinkKind.ResetPassword when isEn => new AccountLinkLabels(
                "en", "Reset your password",
                "Open the app or continue in the browser to choose a new password.",
                "Continue on web", "Get on Google Play", "Get on App Store",
                "CraftQuestAI password reset"),
            AccountLinkKind.ResetPassword when isPt => new AccountLinkLabels(
                "pt", "Redefinir sua senha",
                "Abra o app ou continue no navegador para escolher uma nova senha.",
                "Continuar na web", "Baixar no Google Play", "Baixar na App Store",
                "Redefinicao de senha CraftQuestAI"),
            AccountLinkKind.ResetPassword => new AccountLinkLabels(
                "es", "Restablecer contrasena",
                "Abre la app o continua en el navegador para elegir una nueva contrasena.",
                "Continuar en la web", "Descargar en Google Play", "Descargar en App Store",
                "Restablecimiento de contrasena CraftQuestAI"),
            AccountLinkKind.ParentalConsent when isEn => new AccountLinkLabels(
                "en", "Parental consent",
                "Open the app or continue in the browser to authorize the minor's account.",
                "Continue on web", "Get on Google Play", "Get on App Store",
                "CraftQuestAI parental consent"),
            AccountLinkKind.ParentalConsent when isPt => new AccountLinkLabels(
                "pt", "Consentimento parental",
                "Abra o app ou continue no navegador para autorizar a conta do menor.",
                "Continuar na web", "Baixar no Google Play", "Baixar na App Store",
                "Consentimento parental CraftQuestAI"),
            AccountLinkKind.ParentalConsent => new AccountLinkLabels(
                "es", "Consentimiento parental",
                "Abre la app o continua en el navegador para autorizar la cuenta del menor.",
                "Continuar en la web", "Descargar en Google Play", "Descargar en App Store",
                "Consentimiento parental CraftQuestAI"),
            AccountLinkKind.ConfirmPasswordChange when isEn => new AccountLinkLabels(
                "en", "Confirm password change",
                "Open the app or continue in the browser to confirm your new password.",
                "Continue on web", "Get on Google Play", "Get on App Store",
                "CraftQuestAI password change"),
            AccountLinkKind.ConfirmPasswordChange when isPt => new AccountLinkLabels(
                "pt", "Confirmar alteracao de senha",
                "Abra o app ou continue no navegador para confirmar sua nova senha.",
                "Continuar na web", "Baixar no Google Play", "Baixar na App Store",
                "Alteracao de senha CraftQuestAI"),
            AccountLinkKind.ConfirmPasswordChange => new AccountLinkLabels(
                "es", "Confirmar cambio de contrasena",
                "Abre la app o continua en el navegador para confirmar tu nueva contrasena.",
                "Continuar en la web", "Descargar en Google Play", "Descargar en App Store",
                "Cambio de contrasena CraftQuestAI"),
        };
    }

    private sealed record AccountLinkLabels(
        string Lang,
        string Title,
        string Subtitle,
        string ContinueWeb,
        string GetAndroid,
        string GetIos,
        string FooterNote);

    private static string BuildDocument(
        string title,
        string body,
        LandingLabels labels,
        bool initialShowFallback = true)
    {
        var fallbackClass = initialShowFallback ? "show-fallback" : string.Empty;
        return $$"""
            <!DOCTYPE html>
            <html lang="{{labels.Lang}}">
            <head>
              <meta charset="utf-8" />
              <meta name="viewport" content="width=device-width, initial-scale=1" />
              <title>{{WebUtility.HtmlEncode(title)}}</title>
              <style>
                :root {
                  --bg: #1A2F35;
                  --surface: #263238;
                  --accent: #4ECDC4;
                  --accent-soft: rgba(78, 205, 196, 0.15);
                  --text: #FDFDFD;
                  --muted: #A9B7C0;
                }
                * { box-sizing: border-box; }
                body {
                  margin: 0;
                  min-height: 100vh;
                  font-family: "Segoe UI", system-ui, -apple-system, sans-serif;
                  background: linear-gradient(160deg, var(--bg) 0%, #0f1c20 100%);
                  color: var(--text);
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  padding: 24px;
                }
                .card {
                  width: min(100%, 440px);
                  background: var(--surface);
                  border: 1px solid rgba(78, 205, 196, 0.25);
                  border-radius: 20px;
                  padding: 28px 24px 24px;
                  box-shadow: 0 24px 48px rgba(0, 0, 0, 0.35);
                }
                .brand {
                  margin: 0 0 12px;
                  font-size: 0.75rem;
                  letter-spacing: 0.14em;
                  text-transform: uppercase;
                  color: var(--accent);
                  font-weight: 700;
                }
                .eyebrow {
                  margin: 0 0 6px;
                  font-size: 0.85rem;
                  color: var(--muted);
                }
                h1 {
                  margin: 0 0 10px;
                  font-size: 1.45rem;
                  line-height: 1.25;
                }
                .subtitle {
                  margin: 0 0 20px;
                  color: var(--muted);
                  font-size: 0.95rem;
                  line-height: 1.45;
                }
                .code-box {
                  background: var(--accent-soft);
                  border: 1px dashed rgba(78, 205, 196, 0.45);
                  border-radius: 14px;
                  padding: 16px;
                  text-align: center;
                  margin-bottom: 18px;
                }
                .code-label {
                  display: block;
                  font-size: 0.75rem;
                  color: var(--muted);
                  margin-bottom: 6px;
                }
                .code-value {
                  display: block;
                  font-size: 1.65rem;
                  font-weight: 700;
                  letter-spacing: 0.08em;
                  margin-bottom: 12px;
                }
                .actions {
                  display: none;
                  flex-direction: column;
                  gap: 10px;
                }
                body.show-fallback .actions,
                .actions.show-fallback {
                  display: flex;
                }
                .btn {
                  display: block;
                  width: 100%;
                  text-align: center;
                  text-decoration: none;
                  border-radius: 12px;
                  padding: 13px 16px;
                  font-size: 0.95rem;
                  font-weight: 600;
                  border: none;
                  cursor: pointer;
                }
                .btn.primary {
                  background: var(--accent);
                  color: #0f1c20;
                }
                .btn.store {
                  background: transparent;
                  color: var(--text);
                  border: 1px solid rgba(253, 253, 253, 0.25);
                }
                .btn.ghost {
                  background: transparent;
                  color: var(--accent);
                  border: 1px solid rgba(78, 205, 196, 0.45);
                  width: auto;
                  margin: 0 auto;
                  padding: 8px 14px;
                  font-size: 0.85rem;
                }
                .code-form input {
                  width: 100%;
                  padding: 12px 14px;
                  border-radius: 12px;
                  border: 1px solid rgba(169, 183, 192, 0.35);
                  background: #1A2F35;
                  color: var(--text);
                  font-size: 1rem;
                  margin-bottom: 12px;
                  text-transform: uppercase;
                }
                .footer-note {
                  margin: 18px 0 0;
                  text-align: center;
                  font-size: 0.75rem;
                  color: var(--muted);
                }
              </style>
            </head>
            <body class="{{fallbackClass}}">
              {{body}}
            </body>
            </html>
            """;
    }

    private static LandingLabels ResolveLabels(string? acceptLanguage)
    {
        var lang = acceptLanguage?.Split(',').FirstOrDefault()?.Trim().ToLowerInvariant() ?? "es";
        if (lang.StartsWith("en", StringComparison.Ordinal))
        {
            return new LandingLabels(
                Lang: "en",
                PageTitle: "Join · CraftQuestAI",
                JoinTitle: "Join quiz",
                EnterCodeTitle: "Enter your access code",
                EnterCodeSubtitle: "Enter the code shared by your teacher or classmate.",
                CodeLabel: "Access code",
                CopyCode: "Copy code",
                ContinueWeb: "Continue on web",
                GetAndroid: "Get on Google Play",
                GetIos: "Get on App Store",
                GuestOpenHint: "Practice without an account or sign in from the web app.",
                GroupOnlyHint: "This quiz is for class members. Sign in with your account on the web.",
                OpenHint: "Open the link on your device or continue in the browser.",
                FooterNote: "Generated by CraftQuestAI");
        }

        if (lang.StartsWith("pt", StringComparison.Ordinal))
        {
            return new LandingLabels(
                Lang: "pt",
                PageTitle: "Entrar · CraftQuestAI",
                JoinTitle: "Entrar no questionario",
                EnterCodeTitle: "Introduza o codigo de acesso",
                EnterCodeSubtitle: "Use o codigo compartilhado pelo professor ou colega.",
                CodeLabel: "Codigo de acesso",
                CopyCode: "Copiar codigo",
                ContinueWeb: "Continuar na web",
                GetAndroid: "Baixar no Google Play",
                GetIos: "Baixar na App Store",
                GuestOpenHint: "Pratique sem conta ou entre pela web.",
                GroupOnlyHint: "Este questionario e para membros da turma. Entre com sua conta na web.",
                OpenHint: "Abra o link no seu dispositivo ou continue no navegador.",
                FooterNote: "Gerado por CraftQuestAI");
        }

        return new LandingLabels(
            Lang: "es",
            PageTitle: "Unirse · CraftQuestAI",
            JoinTitle: "Unirse al cuestionario",
            EnterCodeTitle: "Introduce tu codigo de acceso",
            EnterCodeSubtitle: "Usa el codigo que te compartio tu profesor o companero.",
            CodeLabel: "Codigo de acceso",
            CopyCode: "Copiar codigo",
            ContinueWeb: "Continuar en la web",
            GetAndroid: "Descargar en Google Play",
            GetIos: "Descargar en App Store",
            GuestOpenHint: "Practica sin cuenta o inicia sesion desde la web.",
            GroupOnlyHint: "Este cuestionario es para miembros del grupo. Inicia sesion en la web.",
            OpenHint: "Abre el enlace en tu dispositivo o continua en el navegador.",
            FooterNote: "Generado por CraftQuestAI");
    }

    private sealed record LandingLabels(
        string Lang,
        string PageTitle,
        string JoinTitle,
        string EnterCodeTitle,
        string EnterCodeSubtitle,
        string CodeLabel,
        string CopyCode,
        string ContinueWeb,
        string GetAndroid,
        string GetIos,
        string GuestOpenHint,
        string GroupOnlyHint,
        string OpenHint,
        string FooterNote);
}
