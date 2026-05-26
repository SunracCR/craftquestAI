-- ============================================================
-- Guest Mode: sesiones efímeras sin cuenta
-- ============================================================

-- 1. Crear schema guest
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'guest')
    EXEC('CREATE SCHEMA [guest]');
GO

-- 2. Tabla GuestVisits
CREATE TABLE [guest].[GuestVisits] (
    [GuestVisitId]     UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    [QuizId]           UNIQUEIDENTIFIER NOT NULL,
    [Token]            NVARCHAR(64)     NOT NULL,
    [CreatedAt]        DATETIME2        NOT NULL,
    [ExpiresAt]        DATETIME2        NOT NULL,
    [LastActivityAt]   DATETIME2        NOT NULL,
    CONSTRAINT [PK_GuestVisits] PRIMARY KEY ([GuestVisitId]),
    CONSTRAINT [UQ_GuestVisits_Token] UNIQUE ([Token]),
    CONSTRAINT [FK_GuestVisits_Quizzes] FOREIGN KEY ([QuizId])
        REFERENCES [quiz].[Quizzes]([QuizId])
);
GO

CREATE INDEX [IX_GuestVisits_Token]     ON [guest].[GuestVisits]([Token]);
CREATE INDEX [IX_GuestVisits_ExpiresAt] ON [guest].[GuestVisits]([ExpiresAt]);
GO

-- 3. Agregar columna GuestVisitId a PracticeSessions
ALTER TABLE [practice].[PracticeSessions]
    ADD [GuestVisitId] UNIQUEIDENTIFIER NULL;
GO

-- 4. Hacer StudentUserId nullable
ALTER TABLE [practice].[PracticeSessions]
    ALTER COLUMN [StudentUserId] UNIQUEIDENTIFIER NULL;
GO

-- 5. FK con cascade delete hacia GuestVisits
ALTER TABLE [practice].[PracticeSessions]
    ADD CONSTRAINT [FK_PracticeSessions_GuestVisits]
        FOREIGN KEY ([GuestVisitId])
        REFERENCES [guest].[GuestVisits]([GuestVisitId])
        ON DELETE CASCADE;
GO

-- 6. Índice filtrado (el GO anterior es necesario para que SQL Server
--    reconozca la columna recién añadida en la misma sesión)
CREATE INDEX [IX_PracticeSessions_GuestVisitId]
    ON [practice].[PracticeSessions]([GuestVisitId])
    WHERE [GuestVisitId] IS NOT NULL;
GO
