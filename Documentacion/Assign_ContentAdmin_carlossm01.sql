/* Asigna rol content_admin a carlossm01@gmail.com (re-ejecutable) */

DECLARE @Email NVARCHAR(320) = N'carlossm01@gmail.com';

DECLARE @UserId UNIQUEIDENTIFIER;
SELECT @UserId = UserId
FROM core.Users
WHERE EmailNormalized = UPPER(@Email)
  AND DeletedAt IS NULL;

IF @UserId IS NULL
BEGIN
    RAISERROR(N'Usuario no encontrado: %s. Regístrate primero en la app.', 16, 1, @Email);
    RETURN;
END;

DECLARE @RoleId INT;
SELECT @RoleId = RoleId FROM core.Roles WHERE Code = N'content_admin';

IF @RoleId IS NULL
BEGIN
    RAISERROR(N'Rol content_admin no existe. Ejecuta el seed de core.Roles del DDL.', 16, 1);
    RETURN;
END;

IF NOT EXISTS (
    SELECT 1 FROM core.UserRoles
    WHERE UserId = @UserId AND RoleId = @RoleId
)
BEGIN
    INSERT INTO core.UserRoles (UserId, RoleId)
    VALUES (@UserId, @RoleId);
    PRINT N'Rol content_admin asignado a ' + @Email;
END
ELSE
    PRINT N'El usuario ya tenía content_admin.';

SELECT u.Email, r.Code AS RoleCode, r.Name AS RoleName
FROM core.Users u
INNER JOIN core.UserRoles ur ON ur.UserId = u.UserId
INNER JOIN core.Roles r ON r.RoleId = ur.RoleId
WHERE u.UserId = @UserId
ORDER BY r.Code;
