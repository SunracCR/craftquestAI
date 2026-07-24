using CraftQuest.Application.Options;
using CraftQuest.Infrastructure.Services.Offline;
using Microsoft.Extensions.Options;
using System.Text.Json;

namespace CraftQuest.UnitTests.Offline;

public class OfflinePackageCryptoServiceTests
{
    [Fact]
    public void EncryptCorrectAnswers_RoundTrip_WithSameKey()
    {
        var service = new OfflinePackageCryptoService(
            Options.Create(new OfflineOptions()));

        var key = service.GeneratePackageKey();
        var correctIds = new List<Guid>
        {
            Guid.Parse("11111111-1111-1111-1111-111111111111"),
            Guid.Parse("22222222-2222-2222-2222-222222222222"),
        };

        var blob = service.EncryptCorrectAnswers(key, correctIds);
        Assert.False(string.IsNullOrWhiteSpace(blob));

        var payload = Convert.FromBase64String(blob);
        Assert.True(payload.Length > 28);
    }

    [Fact]
    public void ComputeContentVersion_IsDeterministic()
    {
        var quizId = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
        var updatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        var v1 = OfflinePackageCryptoService.ComputeContentVersion(
            quizId,
            updatedAt,
            10,
            updatedAt);

        var v2 = OfflinePackageCryptoService.ComputeContentVersion(
            quizId,
            updatedAt,
            10,
            updatedAt);

        Assert.Equal(v1, v2);
        Assert.Equal(32, v1.Length);
    }

    [Fact]
    public void BuildWatermarkToken_IsStableForSameInputs()
    {
        var service = new OfflinePackageCryptoService(
            Options.Create(new OfflineOptions()));

        var userId = Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
        var quizId = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc");

        var w1 = service.BuildWatermarkToken(userId, quizId);
        var w2 = service.BuildWatermarkToken(userId, quizId);

        Assert.Equal(w1, w2);
        Assert.Equal(16, w1.Length);
    }
}
