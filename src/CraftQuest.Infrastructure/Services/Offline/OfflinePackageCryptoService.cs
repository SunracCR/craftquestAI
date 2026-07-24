using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using CraftQuest.Application.Options;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Offline;

public sealed class OfflinePackageCryptoService(IOptions<OfflineOptions> options)
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public byte[] GeneratePackageKey() => RandomNumberGenerator.GetBytes(32);

    public string EncryptCorrectAnswers(byte[] packageKey, IReadOnlyList<Guid> correctAnswerOptionIds)
    {
        var plaintext = JsonSerializer.SerializeToUtf8Bytes(
            correctAnswerOptionIds,
            JsonOptions);

        var nonce = RandomNumberGenerator.GetBytes(AesGcm.NonceByteSizes.MaxSize);
        var ciphertext = new byte[plaintext.Length];
        var tag = new byte[AesGcm.TagByteSizes.MaxSize];

        using var aes = new AesGcm(packageKey, AesGcm.TagByteSizes.MaxSize);
        aes.Encrypt(nonce, plaintext, ciphertext, tag);

        var payload = new byte[nonce.Length + tag.Length + ciphertext.Length];
        Buffer.BlockCopy(nonce, 0, payload, 0, nonce.Length);
        Buffer.BlockCopy(tag, 0, payload, nonce.Length, tag.Length);
        Buffer.BlockCopy(ciphertext, 0, payload, nonce.Length + tag.Length, ciphertext.Length);
        return Convert.ToBase64String(payload);
    }

    public string BuildWatermarkToken(Guid userId, Guid quizId)
    {
        var secret = options.Value.EncryptionSecret;
        var input = $"{userId:N}:{quizId:N}:{secret}";
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(input));
        return Convert.ToHexString(hash)[..16].ToLowerInvariant();
    }

    public static string ComputeContentVersion(
        Guid quizId,
        DateTime? quizUpdatedAt,
        int questionCount,
        DateTime? maxQuestionUpdatedAt)
    {
        var payload = $"{quizId:N}|{quizUpdatedAt:O}|{questionCount}|{maxQuestionUpdatedAt:O}";
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(payload));
        return Convert.ToHexString(hash)[..32].ToLowerInvariant();
    }
}
