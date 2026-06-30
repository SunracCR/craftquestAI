using System.ComponentModel.DataAnnotations;

namespace CraftQuest.Application.Models.Auth;

public class ConfirmParentalConsentRequest
{
    [Required]
    public string Token { get; set; } = string.Empty;
}

public class ResendParentalConsentRequest
{
    [Required, EmailAddress, MaxLength(320)]
    public string Email { get; set; } = string.Empty;
}
