-- Email verification + password change confirmation tokens
-- Idempotent. Run after MVP DDL and PasswordReset_Feature.sql.

-- Allow pending users awaiting email verification
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
            CHECK (Status IN ('pending','active','suspended','deleted'));
END;

IF COL_LENGTH('core.Users', 'EmailVerifiedAt') IS NULL
BEGIN
    ALTER TABLE core.Users
        ADD EmailVerifiedAt DATETIME2(3) NULL;
END;
GO

-- Existing active users are treated as already verified.
-- Must be a separate batch so SQL Server sees EmailVerifiedAt after ADD.
IF COL_LENGTH('core.Users', 'EmailVerifiedAt') IS NOT NULL
BEGIN
    UPDATE core.Users
    SET EmailVerifiedAt = CreatedAt
    WHERE Status = 'active'
      AND EmailVerifiedAt IS NULL;
END;
GO

IF OBJECT_ID(N'core.EmailVerificationTokens', N'U') IS NULL
BEGIN
    CREATE TABLE core.EmailVerificationTokens
    (
        EmailVerificationTokenId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_EmailVerificationTokens PRIMARY KEY,
        UserId                   UNIQUEIDENTIFIER NOT NULL,
        TokenHash                NVARCHAR(128)    NOT NULL,
        ExpiresAt                DATETIME2(3)     NOT NULL,
        CreatedAt                DATETIME2(3)     NOT NULL,
        UsedAt                   DATETIME2(3)     NULL,
        CONSTRAINT FK_EmailVerificationTokens_Users_UserId
            FOREIGN KEY (UserId) REFERENCES core.Users (UserId) ON DELETE CASCADE
    );

    CREATE INDEX IX_EmailVerificationTokens_TokenHash
        ON core.EmailVerificationTokens (TokenHash);

    CREATE INDEX IX_EmailVerificationTokens_UserId_UsedAt
        ON core.EmailVerificationTokens (UserId, UsedAt);
END;

IF OBJECT_ID(N'core.PasswordChangeTokens', N'U') IS NULL
BEGIN
    CREATE TABLE core.PasswordChangeTokens
    (
        PasswordChangeTokenId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_PasswordChangeTokens PRIMARY KEY,
        UserId                UNIQUEIDENTIFIER NOT NULL,
        TokenHash             NVARCHAR(128)    NOT NULL,
        NewPasswordHash       VARBINARY(256)   NOT NULL,
        ExpiresAt             DATETIME2(3)     NOT NULL,
        CreatedAt             DATETIME2(3)     NOT NULL,
        UsedAt                DATETIME2(3)     NULL,
        CONSTRAINT FK_PasswordChangeTokens_Users_UserId
            FOREIGN KEY (UserId) REFERENCES core.Users (UserId) ON DELETE CASCADE
    );

    CREATE INDEX IX_PasswordChangeTokens_TokenHash
        ON core.PasswordChangeTokens (TokenHash);

    CREATE INDEX IX_PasswordChangeTokens_UserId_UsedAt
        ON core.PasswordChangeTokens (UserId, UsedAt);
END;
