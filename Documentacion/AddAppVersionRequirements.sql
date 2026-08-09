-- Ítem 66 del checklist: tabla core.AppVersionRequirements para forzar
-- actualización mínima de la app móvil (Android / iOS).
-- Idempotente: seguro re-ejecutar.

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'core')
BEGIN
    EXEC('CREATE SCHEMA core');
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE s.name = 'core' AND t.name = 'AppVersionRequirements'
)
BEGIN
    CREATE TABLE core.AppVersionRequirements (
        AppVersionRequirementId INT IDENTITY(1,1) NOT NULL,
        Platform NVARCHAR(20) NOT NULL,
        MinSupportedVersion NVARCHAR(30) NOT NULL,
        LatestVersion NVARCHAR(30) NULL,
        UpdateUrl NVARCHAR(500) NOT NULL,
        Message NVARCHAR(1000) NULL,
        UpdatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_AppVersionRequirements_UpdatedAtUtc DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_AppVersionRequirements PRIMARY KEY CLUSTERED (AppVersionRequirementId)
    );

    CREATE UNIQUE INDEX UQ_AppVersionRequirements_Platform
        ON core.AppVersionRequirements (Platform);
END
GO

-- Seed inicial: NO bloqueante. MinSupportedVersion = versión actual publicada
-- (pubspec.yaml al momento de este script). Ajustar manualmente vía
-- PUT /api/app-version/{platform} (rol super_admin) cuando quieras forzar
-- una actualización real subiendo MinSupportedVersion.
IF NOT EXISTS (SELECT 1 FROM core.AppVersionRequirements WHERE Platform = 'android')
BEGIN
    INSERT INTO core.AppVersionRequirements (Platform, MinSupportedVersion, LatestVersion, UpdateUrl, Message)
    VALUES (
        'android',
        '1.0.4',
        '1.0.4',
        'https://play.google.com/store/apps/details?id=com.craftquestai.craftquestai_app',
        NULL
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM core.AppVersionRequirements WHERE Platform = 'ios')
BEGIN
    INSERT INTO core.AppVersionRequirements (Platform, MinSupportedVersion, LatestVersion, UpdateUrl, Message)
    VALUES (
        'ios',
        '1.0.4',
        '1.0.4',
        'https://apps.apple.com/app/idPENDIENTE',
        NULL
    );
END
GO
