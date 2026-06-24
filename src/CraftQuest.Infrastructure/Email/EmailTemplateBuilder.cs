using System.Net;

namespace CraftQuest.Infrastructure.Email;

public static class EmailTemplateBuilder
{
    public static (string Subject, string PlainText, string Html) BuildVerifyEmail(
        string language,
        string actionUrl,
        int lifetimeMinutes)
    {
        return language switch
        {
            "en" => (
                "Activate your CraftQuestAI account",
                $"Welcome! Activate your account using this link (valid for {lifetimeMinutes} minutes):\n\n{actionUrl}\n\nIf you did not create an account, you can ignore this email.",
                BuildHtml(
                    "Activate your account",
                    "Welcome to CraftQuestAI",
                    $"Tap the button below to activate your account. This link expires in {lifetimeMinutes} minutes.",
                    "Activate account",
                    actionUrl,
                    "If you did not create an account, you can ignore this email.")),
            "pt" => (
                "Ative sua conta CraftQuestAI",
                $"Bem-vindo! Ative sua conta usando este link (valido por {lifetimeMinutes} minutos):\n\n{actionUrl}\n\nSe voce nao criou uma conta, ignore este e-mail.",
                BuildHtml(
                    "Ative sua conta",
                    "Bem-vindo ao CraftQuestAI",
                    $"Toque no botao abaixo para ativar sua conta. Este link expira em {lifetimeMinutes} minutos.",
                    "Ativar conta",
                    actionUrl,
                    "Se voce nao criou uma conta, ignore este e-mail.")),
            _ => (
                "Activa tu cuenta de CraftQuestAI",
                $"¡Bienvenido! Activa tu cuenta con este enlace (válido {lifetimeMinutes} minutos):\n\n{actionUrl}\n\nSi no creaste una cuenta, ignora este correo.",
                BuildHtml(
                    "Activa tu cuenta",
                    "Bienvenido a CraftQuestAI",
                    $"Pulsa el botón para activar tu cuenta. El enlace caduca en {lifetimeMinutes} minutos.",
                    "Activar cuenta",
                    actionUrl,
                    "Si no creaste una cuenta, ignora este correo.")),
        };
    }

    public static (string Subject, string PlainText, string Html) BuildPasswordReset(
        string language,
        string actionUrl,
        int lifetimeMinutes)
    {
        return language switch
        {
            "en" => (
                "Reset your CraftQuestAI password",
                $"Use this link to choose a new password (valid for {lifetimeMinutes} minutes):\n\n{actionUrl}\n\nIf you did not request this, you can ignore this email.",
                BuildHtml(
                    "Reset password",
                    "Password reset",
                    $"Use the button below to choose a new password. This link expires in {lifetimeMinutes} minutes.",
                    "Reset password",
                    actionUrl,
                    "If you did not request this, you can ignore this email.")),
            "pt" => (
                "Redefinir sua senha CraftQuestAI",
                $"Use este link para escolher uma nova senha (valido por {lifetimeMinutes} minutos):\n\n{actionUrl}\n\nSe voce nao solicitou isso, ignore este e-mail.",
                BuildHtml(
                    "Redefinir senha",
                    "Redefinicao de senha",
                    $"Use o botao abaixo para escolher uma nova senha. Este link expira em {lifetimeMinutes} minutos.",
                    "Redefinir senha",
                    actionUrl,
                    "Se voce nao solicitou isso, ignore este e-mail.")),
            _ => (
                "Restablecer tu contraseña de CraftQuestAI",
                $"Usa este enlace para elegir una nueva contraseña (válido {lifetimeMinutes} minutos):\n\n{actionUrl}\n\nSi no lo solicitaste, ignora este correo.",
                BuildHtml(
                    "Restablecer contraseña",
                    "Restablecer contraseña",
                    $"Pulsa el botón para elegir una nueva contraseña. El enlace caduca en {lifetimeMinutes} minutos.",
                    "Restablecer contraseña",
                    actionUrl,
                    "Si no lo solicitaste, ignora este correo.")),
        };
    }

    public static (string Subject, string PlainText, string Html) BuildConfirmPasswordChange(
        string language,
        string actionUrl,
        int lifetimeMinutes)
    {
        return language switch
        {
            "en" => (
                "Confirm your CraftQuestAI password change",
                $"Confirm your new password using this link (valid for {lifetimeMinutes} minutes):\n\n{actionUrl}\n\nIf you did not request this change, secure your account immediately.",
                BuildHtml(
                    "Confirm password change",
                    "Confirm password change",
                    $"Your new password will only take effect after you confirm via the button below. This link expires in {lifetimeMinutes} minutes.",
                    "Confirm change",
                    actionUrl,
                    "If you did not request this change, secure your account immediately.")),
            "pt" => (
                "Confirme a alteracao de senha CraftQuestAI",
                $"Confirme sua nova senha usando este link (valido por {lifetimeMinutes} minutos):\n\n{actionUrl}\n\nSe voce nao solicitou esta alteracao, proteja sua conta imediatamente.",
                BuildHtml(
                    "Confirmar alteracao de senha",
                    "Confirmar alteracao de senha",
                    $"Sua nova senha so sera aplicada apos confirmar pelo botao abaixo. Este link expira em {lifetimeMinutes} minutos.",
                    "Confirmar alteracao",
                    actionUrl,
                    "Se voce nao solicitou esta alteracao, proteja sua conta imediatamente.")),
            _ => (
                "Confirma el cambio de contraseña de CraftQuestAI",
                $"Confirma tu nueva contraseña con este enlace (válido {lifetimeMinutes} minutos):\n\n{actionUrl}\n\nSi no solicitaste este cambio, protege tu cuenta de inmediato.",
                BuildHtml(
                    "Confirmar cambio de contraseña",
                    "Confirmar cambio de contraseña",
                    $"La nueva contraseña solo se aplicará tras confirmar con el botón. El enlace caduca en {lifetimeMinutes} minutos.",
                    "Confirmar cambio",
                    actionUrl,
                    "Si no solicitaste este cambio, protege tu cuenta de inmediato.")),
        };
    }

    private static string BuildHtml(
        string preheader,
        string title,
        string body,
        string buttonLabel,
        string actionUrl,
        string footerNote)
    {
        var encodedTitle = WebUtility.HtmlEncode(title);
        var encodedBody = WebUtility.HtmlEncode(body);
        var encodedButton = WebUtility.HtmlEncode(buttonLabel);
        var encodedUrl = WebUtility.HtmlEncode(actionUrl);
        var encodedFooter = WebUtility.HtmlEncode(footerNote);
        var encodedPreheader = WebUtility.HtmlEncode(preheader);

        return $$"""
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="utf-8" />
              <meta name="viewport" content="width=device-width, initial-scale=1" />
              <title>{{encodedTitle}}</title>
            </head>
            <body style="margin:0;padding:0;background:#1A2F35;font-family:'Segoe UI',system-ui,-apple-system,sans-serif;">
              <span style="display:none;max-height:0;overflow:hidden;">{{encodedPreheader}}</span>
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#1A2F35;padding:32px 16px;">
                <tr>
                  <td align="center">
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:520px;background:#263238;border:1px solid rgba(78,205,196,0.25);border-radius:16px;padding:28px 24px;">
                      <tr>
                        <td style="color:#4ECDC4;font-size:12px;font-weight:700;letter-spacing:0.14em;text-transform:uppercase;padding-bottom:12px;">
                          CraftQuestAI
                        </td>
                      </tr>
                      <tr>
                        <td style="color:#FDFDFD;font-size:22px;font-weight:700;line-height:1.3;padding-bottom:12px;">
                          {{encodedTitle}}
                        </td>
                      </tr>
                      <tr>
                        <td style="color:#A9B7C0;font-size:15px;line-height:1.5;padding-bottom:24px;">
                          {{encodedBody}}
                        </td>
                      </tr>
                      <tr>
                        <td align="center" style="padding-bottom:24px;">
                          <a href="{{encodedUrl}}" style="display:inline-block;background:#4ECDC4;color:#1A2F35;text-decoration:none;font-weight:700;padding:14px 28px;border-radius:999px;">
                            {{encodedButton}}
                          </a>
                        </td>
                      </tr>
                      <tr>
                        <td style="color:#A9B7C0;font-size:13px;line-height:1.45;padding-bottom:16px;">
                          {{encodedFooter}}
                        </td>
                      </tr>
                      <tr>
                        <td style="color:#4ECDC4;font-size:12px;">
                          www.CraftQuestAI.com
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </body>
            </html>
            """;
    }
}
