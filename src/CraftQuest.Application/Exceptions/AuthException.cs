namespace CraftQuest.Application.Exceptions;

public class AuthException(string message, int statusCode = 400, string? errorCode = null)
    : AppException(message, statusCode, errorCode);
