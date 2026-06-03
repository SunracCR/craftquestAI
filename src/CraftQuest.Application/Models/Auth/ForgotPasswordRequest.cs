using System.ComponentModel.DataAnnotations;

namespace CraftQuest.Application.Models.Auth;

public class ForgotPasswordRequest
{
    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;
}
