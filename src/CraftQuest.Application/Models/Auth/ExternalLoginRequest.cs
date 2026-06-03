using System.ComponentModel.DataAnnotations;

namespace CraftQuest.Application.Models.Auth;

public sealed class ExternalLoginRequest
{
    [Required]
    public string IdToken { get; set; } = string.Empty;

    /// <summary>Email enviado por el cliente en el primer inicio con Apple (solo primera vez).</summary>
    public string? Email { get; set; }

    /// <summary>Nombre mostrado enviado por el cliente en el primer inicio con Apple.</summary>
    public string? DisplayName { get; set; }
}
