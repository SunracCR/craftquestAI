namespace CraftQuest.Application.Constants;

public static class ShareCodeDefaults
{
    public const string MultiUseCodeType = "class_capacity";

    /// <summary>Estudiante comparte: muchos usos, invitados y registrados.</summary>
    public const int StudentMaxRedemptions = 500;

    /// <summary>Profesor — abierto a cualquiera.</summary>
    public const int TeacherOpenMaxRedemptions = 500;

    /// <summary>Profesor — solo miembros del grupo.</summary>
    public const int TeacherGroupMaxRedemptions = 200;
}
