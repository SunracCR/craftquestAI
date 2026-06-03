using System.ComponentModel.DataAnnotations;

namespace CraftQuest.Application.Models.Auth;

public class ResetPasswordRequest
{
    [Required, MinLength(20)]
    public string Token { get; set; } = string.Empty;

    [Required, MinLength(8)]
    public string NewPassword { get; set; } = string.Empty;
}
