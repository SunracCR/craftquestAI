-- Avatar e idioma preferido del usuario (perfil).
IF COL_LENGTH('core.Users', 'AvatarId') IS NULL
BEGIN
    ALTER TABLE core.Users ADD AvatarId NVARCHAR(40) NULL;
END
GO

IF COL_LENGTH('core.Users', 'PreferredLanguage') IS NULL
BEGIN
    ALTER TABLE core.Users ADD PreferredLanguage NVARCHAR(5) NULL;
END
GO

SET QUOTED_IDENTIFIER ON;
GO

UPDATE core.Users
SET AvatarId = 'craft_01'
WHERE AvatarId IS NULL AND DeletedAt IS NULL;
GO
