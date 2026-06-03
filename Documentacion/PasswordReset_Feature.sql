-- Password reset tokens (core.PasswordResetTokens)
-- Idempotent. Run after MVP DDL.

IF OBJECT_ID(N'core.PasswordResetTokens', N'U') IS NULL
BEGIN
    CREATE TABLE core.PasswordResetTokens
    (
        PasswordResetTokenId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_PasswordResetTokens PRIMARY KEY,
        UserId               UNIQUEIDENTIFIER NOT NULL,
        TokenHash            NVARCHAR(128)    NOT NULL,
        ExpiresAt            DATETIME2(3)     NOT NULL,
        CreatedAt            DATETIME2(3)     NOT NULL,
        UsedAt               DATETIME2(3)     NULL,
        CONSTRAINT FK_PasswordResetTokens_Users_UserId
            FOREIGN KEY (UserId) REFERENCES core.Users (UserId) ON DELETE CASCADE
    );

    CREATE INDEX IX_PasswordResetTokens_TokenHash
        ON core.PasswordResetTokens (TokenHash);

    CREATE INDEX IX_PasswordResetTokens_UserId_UsedAt
        ON core.PasswordResetTokens (UserId, UsedAt);
END;
