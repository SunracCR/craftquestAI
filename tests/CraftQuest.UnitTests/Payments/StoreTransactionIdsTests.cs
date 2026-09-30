using System.Text;
using CraftQuest.Application.Exceptions;
using CraftQuest.Infrastructure.Services.Payments;

namespace CraftQuest.UnitTests.Payments;

public class StoreTransactionIdsTests
{
    [Fact]
    public void Normalize_ShortId_IsUnchanged()
    {
        Assert.Equal("2000000123456789", StoreTransactionIds.Normalize("2000000123456789"));
    }

    [Fact]
    public void Normalize_AppleJws_StoresTransactionIdFromPayload()
    {
        var jws = FakeJws("""{"transactionId":"2000000123456789","productId":"prep_plus_item"}""");

        Assert.Equal("2000000123456789", StoreTransactionIds.Normalize(jws));
    }

    [Fact]
    public void Normalize_AppleJws_ReadsNumericTransactionId()
    {
        var jws = FakeJws("""{"transactionId":2000000123456789}""");

        Assert.Equal("2000000123456789", StoreTransactionIds.Normalize(jws));
    }

    [Fact]
    public void Normalize_UnresolvedJws_ThrowsInsteadOfTruncating()
    {
        var jws = FakeJws("""{"productId":"prep_plus_item"}""");
        jws = string.Concat(jws.AsSpan(0, jws.LastIndexOf('.') + 1), new string('a', 320));

        var ex = Assert.Throws<AppException>(() => StoreTransactionIds.Normalize(jws));

        Assert.Equal(400, ex.StatusCode);
        Assert.Equal("STORE_PURCHASE_INVALID", ex.ErrorCode);
    }

    private static string FakeJws(string payloadJson)
    {
        var header = Base64Url("""{"alg":"ES256","x5c":["MII"]}""");
        var payload = Base64Url(payloadJson);
        return $"{header}.{payload}.sig";
    }

    private static string Base64Url(string value)
    {
        return Convert.ToBase64String(Encoding.UTF8.GetBytes(value))
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');
    }
}
