using System.Security.Cryptography;

namespace CraftQuest.Infrastructure.Security;

public static class PasswordHasher
{
    private const int SaltSize = 16;
    private const int KeySize = 32;
    private const int Iterations = 100_000;

    public static byte[] HashPassword(string password)
    {
        var salt = RandomNumberGenerator.GetBytes(SaltSize);
        var key = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            Iterations,
            HashAlgorithmName.SHA256,
            KeySize);

        var result = new byte[SaltSize + KeySize];
        Buffer.BlockCopy(salt, 0, result, 0, SaltSize);
        Buffer.BlockCopy(key, 0, result, SaltSize, KeySize);
        return result;
    }

    public static bool VerifyPassword(string password, byte[] passwordHash)
    {
        if (passwordHash.Length != SaltSize + KeySize)
        {
            return false;
        }

        var salt = passwordHash.AsSpan(0, SaltSize);
        var expectedKey = passwordHash.AsSpan(SaltSize, KeySize);
        var actualKey = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            Iterations,
            HashAlgorithmName.SHA256,
            KeySize);

        return CryptographicOperations.FixedTimeEquals(expectedKey, actualKey);
    }
}
