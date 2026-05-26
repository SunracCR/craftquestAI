using System.ComponentModel.DataAnnotations;

namespace CraftQuest.Application.Models.Auth;

public class RefreshTokenRequest
{
    [Required]
    public string RefreshToken { get; set; } = string.Empty;
}
