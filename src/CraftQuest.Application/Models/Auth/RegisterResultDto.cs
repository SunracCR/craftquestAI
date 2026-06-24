namespace CraftQuest.Application.Models.Auth;

public class RegisterResultDto
{
    public bool RequiresEmailVerification { get; set; } = true;

    public string Email { get; set; } = string.Empty;
}
