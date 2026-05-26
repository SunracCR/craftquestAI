namespace CraftQuest.Application.Exceptions;

public class AppException : Exception
{
    public AppException(
        string message,
        int statusCode = 400,
        string? errorCode = null,
        IReadOnlyDictionary<string, object?>? metadata = null)
        : base(message)
    {
        StatusCode = statusCode;
        ErrorCode = errorCode;
        Metadata = metadata ?? new Dictionary<string, object?>();
    }

    public int StatusCode { get; }

    public string? ErrorCode { get; }

    public IReadOnlyDictionary<string, object?> Metadata { get; }
}
