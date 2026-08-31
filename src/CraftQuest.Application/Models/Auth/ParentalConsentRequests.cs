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

public class UpdateGuardianEmailRequest
{
    [Required, EmailAddress, MaxLength(320)]
    public string Email { get; set; } = string.Empty;

    [Required, EmailAddress, MaxLength(320)]
    public string GuardianEmail { get; set; } = string.Empty;
}

public sealed class UpdateGuardianEmailResultDto
{
    public required string GuardianEmail { get; init; }
}
