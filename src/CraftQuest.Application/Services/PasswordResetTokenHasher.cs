using System.Security.Cryptography;
using System.Text;

namespace CraftQuest.Application.Services;

public static class PasswordResetTokenHasher
{
    public static string Hash(string token, string pepper)
    {
        var input = Encoding.UTF8.GetBytes($"{token}:{pepper}");
        return Convert.ToHexString(SHA256.HashData(input));
    }

    public static string GenerateToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(32);
        return Convert.ToBase64String(bytes)
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');
    }
}
