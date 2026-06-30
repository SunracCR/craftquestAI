-- Parental consent fields and tokens for mixed-audience compliance.
-- Idempotent. Run after AddEmailVerificationAndPasswordChange.sql.

IF EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = N'CK_Users_Status'
      AND parent_object_id = OBJECT_ID(N'core.Users'))
BEGIN
    ALTER TABLE core.Users DROP CONSTRAINT CK_Users_Status;
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = N'CK_Users_Status'
      AND parent_object_id = OBJECT_ID(N'core.Users'))
BEGIN
    ALTER TABLE core.Users
        ADD CONSTRAINT CK_Users_Status
            CHECK (Status IN ('pending','pending_parental_consent','active','suspended','deleted'));
END;
GO

IF COL_LENGTH('core.Users', 'DateOfBirth') IS NULL
BEGIN
    ALTER TABLE core.Users ADD DateOfBirth DATE NULL;
END
GO

IF COL_LENGTH('core.Users', 'ParentalConsentStatus') IS NULL
BEGIN
    ALTER TABLE core.Users ADD ParentalConsentStatus NVARCHAR(30) NULL;
END
GO

IF COL_LENGTH('core.Users', 'ParentalConsentAt') IS NULL
BEGIN
    ALTER TABLE core.Users ADD ParentalConsentAt DATETIME2(3) NULL;
END
GO

IF COL_LENGTH('core.Users', 'GuardianEmail') IS NULL
BEGIN
    ALTER TABLE core.Users ADD GuardianEmail NVARCHAR(320) NULL;
END
GO

UPDATE core.Users
SET ParentalConsentStatus = N'not_required'
WHERE ParentalConsentStatus IS NULL;
GO

IF OBJECT_ID(N'core.ParentalConsentTokens', N'U') IS NULL
BEGIN
    CREATE TABLE core.ParentalConsentTokens (
        ParentalConsentTokenId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_ParentalConsentTokens PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
        UserId               UNIQUEIDENTIFIER NOT NULL,
        TokenHash            NVARCHAR(128)    NOT NULL,
        ExpiresAt            DATETIME2(3)     NOT NULL,
        CreatedAt            DATETIME2(3)     NOT NULL,
        UsedAt               DATETIME2(3)     NULL,
        CONSTRAINT FK_ParentalConsentTokens_Users
            FOREIGN KEY (UserId) REFERENCES core.Users(UserId) ON DELETE CASCADE
    );

    CREATE INDEX IX_ParentalConsentTokens_TokenHash
        ON core.ParentalConsentTokens (TokenHash);

    CREATE INDEX IX_ParentalConsentTokens_UserId_UsedAt
        ON core.ParentalConsentTokens (UserId, UsedAt);
END
GO
