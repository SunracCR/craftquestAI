namespace CraftQuest.Application.Models.Auth;

public class RegisterResultDto
{
    public bool RequiresEmailVerification { get; set; } = true;

    public bool RequiresParentalConsent { get; set; }

    public string Email { get; set; } = string.Empty;

    public string? GuardianEmail { get; set; }
}
