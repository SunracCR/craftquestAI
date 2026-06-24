namespace CraftQuest.Application.Models.Auth;

public class ChangePasswordResultDto
{
    public bool RequiresEmailConfirmation { get; set; } = true;
}
