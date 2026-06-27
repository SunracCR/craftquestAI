using CraftQuest.Application.Models.Notifications;
using CraftQuest.Domain.Constants;

namespace CraftQuest.Infrastructure.Notifications;

public static class NotificationTextBuilder
{
    public static (string Title, string Body) Build(string type, string language, NotificationPayload payload)
    {
        var lang = NormalizeLanguage(language);
        return type switch
        {
            NotificationTypes.QuizShared => BuildQuizShared(lang, payload),
            NotificationTypes.ClassJoined => BuildClassJoined(lang, payload),
            NotificationTypes.AssignmentCreated => BuildAssignmentCreated(lang, payload),
            NotificationTypes.AssignmentDueSoon => BuildAssignmentDueSoon(lang, payload),
            NotificationTypes.AiJobCompleted => BuildAiJobCompleted(lang, payload),
            NotificationTypes.AiJobFailed => BuildAiJobFailed(lang, payload),
            NotificationTypes.MembershipExpiring => BuildMembershipExpiring(lang, payload),
            NotificationTypes.MembershipExpired => BuildMembershipExpired(lang, payload),
            _ => ("CraftQuest", "You have a new notification."),
        };
    }

    private static string NormalizeLanguage(string? language) =>
        language?.Trim().ToLowerInvariant() switch
        {
            "en" => "en",
            "pt" => "pt",
            _ => "es",
        };

    private static (string, string) BuildQuizShared(string lang, NotificationPayload p)
    {
        var title = p.QuizTitle ?? "Quiz";
        return lang switch
        {
            "en" => ("Quiz shared with you", $"You can now access \"{title}\"."),
            "pt" => ("Questionario compartilhado", $"Voce ja pode acessar \"{title}\"."),
            _ => ("Cuestionario compartido", $"Ya puedes acceder a \"{title}\"."),
        };
    }

    private static (string, string) BuildClassJoined(string lang, NotificationPayload p)
    {
        var className = p.ClassName ?? "Class";
        return lang switch
        {
            "en" => ("Added to a class", $"You were added to \"{className}\"."),
            "pt" => ("Adicionado a uma turma", $"Voce foi adicionado a \"{className}\"."),
            _ => ("Te unieron a una clase", $"Te agregaron a \"{className}\"."),
        };
    }

    private static (string, string) BuildAssignmentCreated(string lang, NotificationPayload p)
    {
        var title = p.AssignmentTitle ?? "Assignment";
        var className = p.ClassName ?? "";
        return lang switch
        {
            "en" => ("New assignment", $"\"{title}\" was assigned in {className}."),
            "pt" => ("Nova tarefa", $"\"{title}\" foi atribuida em {className}."),
            _ => ("Nueva tarea", $"Se asignó \"{title}\" en {className}."),
        };
    }

    private static (string, string) BuildAssignmentDueSoon(string lang, NotificationPayload p)
    {
        var title = p.AssignmentTitle ?? "Assignment";
        var due = p.DueAtLabel ?? "";
        return lang switch
        {
            "en" => ("Assignment due soon", $"\"{title}\" is due {due}."),
            "pt" => ("Tarefa perto do prazo", $"\"{title}\" vence {due}."),
            _ => ("Tarea por vencer", $"\"{title}\" vence {due}."),
        };
    }

    private static (string, string) BuildAiJobCompleted(string lang, NotificationPayload p)
    {
        var title = p.QuizTitle ?? "Quiz";
        return lang switch
        {
            "en" => ("AI quiz ready", $"Your quiz \"{title}\" was generated successfully."),
            "pt" => ("Questionario IA pronto", $"Seu questionario \"{title}\" foi gerado com sucesso."),
            _ => ("Cuestionario IA listo", $"Tu cuestionario \"{title}\" se generó correctamente."),
        };
    }

    private static (string, string) BuildAiJobFailed(string lang, NotificationPayload p)
    {
        var title = p.QuizTitle ?? "Quiz";
        return lang switch
        {
            "en" => ("AI generation failed", $"We could not finish generating \"{title}\". Try again."),
            "pt" => ("Geracao IA falhou", $"Nao foi possivel concluir \"{title}\". Tente novamente."),
            _ => ("Generación IA fallida", $"No se pudo completar \"{title}\". Inténtalo de nuevo."),
        };
    }

    private static (string, string) BuildMembershipExpiring(string lang, NotificationPayload p)
    {
        var plan = p.PlanName ?? "Plan";
        var days = p.DaysRemaining ?? 0;
        return lang switch
        {
            "en" => ("Membership expiring", $"Your {plan} plan expires in {days} day(s)."),
            "pt" => ("Assinatura expirando", $"Seu plano {plan} expira em {days} dia(s)."),
            _ => ("Membresía por vencer", $"Tu plan {plan} vence en {days} día(s)."),
        };
    }

    private static (string, string) BuildMembershipExpired(string lang, NotificationPayload p)
    {
        var plan = p.PlanName ?? "Plan";
        return lang switch
        {
            "en" => ("Membership ended", $"Your {plan} plan has ended. You are now on the Free plan."),
            "pt" => ("Assinatura encerrada", $"Seu plano {plan} terminou. Voce esta no plano Free."),
            _ => ("Membresía vencida", $"Tu plan {plan} terminó. Ahora estás en el plan Free."),
        };
    }
}
