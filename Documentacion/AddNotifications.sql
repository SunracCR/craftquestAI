-- Notifications feature: in-app center, outbox fan-out, device tokens, preferences
-- Idempotent. Run after MVP DDL.

IF OBJECT_ID(N'core.Notifications', N'U') IS NULL
BEGIN
    CREATE TABLE core.Notifications
    (
        NotificationId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Notifications PRIMARY KEY,
        UserId         UNIQUEIDENTIFIER NOT NULL,
        Type           NVARCHAR(60)     NOT NULL,
        Title          NVARCHAR(200)    NOT NULL,
        Body           NVARCHAR(1000)   NOT NULL,
        DataJson       NVARCHAR(4000)   NULL,
        IsRead         BIT              NOT NULL CONSTRAINT DF_Notifications_IsRead DEFAULT (0),
        ReadAt         DATETIME2(3)     NULL,
        CreatedAt      DATETIME2(3)     NOT NULL,
        DedupKey       NVARCHAR(200)    NULL,
        CONSTRAINT FK_Notifications_Users FOREIGN KEY (UserId)
            REFERENCES core.Users (UserId) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_Notifications_User_Read_CreatedAt'
      AND object_id = OBJECT_ID(N'core.Notifications'))
BEGIN
    CREATE INDEX IX_Notifications_User_Read_CreatedAt
        ON core.Notifications (UserId, IsRead, CreatedAt DESC);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_Notifications_User_DedupKey'
      AND object_id = OBJECT_ID(N'core.Notifications'))
BEGIN
    CREATE UNIQUE INDEX UQ_Notifications_User_DedupKey
        ON core.Notifications (UserId, DedupKey)
        WHERE DedupKey IS NOT NULL;
END;
GO

IF OBJECT_ID(N'core.NotificationOutbox', N'U') IS NULL
BEGIN
    CREATE TABLE core.NotificationOutbox
    (
        NotificationOutboxId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_NotificationOutbox PRIMARY KEY,
        EventType            NVARCHAR(60)     NOT NULL,
        PayloadJson          NVARCHAR(4000)   NOT NULL,
        Status               NVARCHAR(30)     NOT NULL CONSTRAINT DF_NotificationOutbox_Status DEFAULT (N'pending'),
        CreatedAt            DATETIME2(3)     NOT NULL,
        ProcessedAt          DATETIME2(3)     NULL
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_NotificationOutbox_Status_CreatedAt'
      AND object_id = OBJECT_ID(N'core.NotificationOutbox'))
BEGIN
    CREATE INDEX IX_NotificationOutbox_Status_CreatedAt
        ON core.NotificationOutbox (Status, CreatedAt);
END;
GO

IF OBJECT_ID(N'core.DeviceTokens', N'U') IS NULL
BEGIN
    CREATE TABLE core.DeviceTokens
    (
        DeviceTokenId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_DeviceTokens PRIMARY KEY,
        UserId        UNIQUEIDENTIFIER NOT NULL,
        Token         NVARCHAR(512)    NOT NULL,
        Platform      NVARCHAR(20)     NOT NULL,
        CreatedAt     DATETIME2(3)     NOT NULL,
        LastSeenAt    DATETIME2(3)     NOT NULL,
        CONSTRAINT FK_DeviceTokens_Users FOREIGN KEY (UserId)
            REFERENCES core.Users (UserId) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_DeviceTokens_Token'
      AND object_id = OBJECT_ID(N'core.DeviceTokens'))
BEGIN
    CREATE UNIQUE INDEX UQ_DeviceTokens_Token
        ON core.DeviceTokens (Token);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_DeviceTokens_UserId'
      AND object_id = OBJECT_ID(N'core.DeviceTokens'))
BEGIN
    CREATE INDEX IX_DeviceTokens_UserId
        ON core.DeviceTokens (UserId);
END;
GO

IF OBJECT_ID(N'core.NotificationPreferences', N'U') IS NULL
BEGIN
    CREATE TABLE core.NotificationPreferences
    (
        NotificationPreferenceId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_NotificationPreferences PRIMARY KEY,
        UserId                     UNIQUEIDENTIFIER NOT NULL,
        Type                       NVARCHAR(60)     NOT NULL,
        InAppEnabled               BIT              NOT NULL CONSTRAINT DF_NotificationPreferences_InApp DEFAULT (1),
        PushEnabled                BIT              NOT NULL CONSTRAINT DF_NotificationPreferences_Push DEFAULT (1),
        EmailEnabled               BIT              NOT NULL CONSTRAINT DF_NotificationPreferences_Email DEFAULT (1),
        CONSTRAINT FK_NotificationPreferences_Users FOREIGN KEY (UserId)
            REFERENCES core.Users (UserId) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_NotificationPreferences_User_Type'
      AND object_id = OBJECT_ID(N'core.NotificationPreferences'))
BEGIN
    CREATE UNIQUE INDEX UQ_NotificationPreferences_User_Type
        ON core.NotificationPreferences (UserId, Type);
END;
GO
