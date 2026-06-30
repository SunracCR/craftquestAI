using System.ComponentModel.DataAnnotations;

namespace CraftQuest.Application.Models.Auth;

public class RegisterRequest
{
    [Required, EmailAddress, MaxLength(320)]
    public string Email { get; set; } = string.Empty;

    [Required, MinLength(8), MaxLength(128)]
    public string Password { get; set; } = string.Empty;

    [MaxLength(160)]
    public string? DisplayName { get; set; }

    public DateOnly? DateOfBirth { get; set; }

    [EmailAddress, MaxLength(320)]
    public string? GuardianEmail { get; set; }
}
