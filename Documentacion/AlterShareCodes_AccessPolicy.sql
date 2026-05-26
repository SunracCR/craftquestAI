-- ============================================================
-- ShareCodes: columna AccessPolicy para modo invitado
-- ============================================================

-- 1. Agregar columna AccessPolicy (default "registered_open" para compatibilidad)
ALTER TABLE [sharing].[ShareCodes]
    ADD [AccessPolicy] NVARCHAR(30) NOT NULL
        CONSTRAINT [DF_ShareCodes_AccessPolicy] DEFAULT 'registered_open';
GO

-- 2. Índice para filtrar rápidamente por política
CREATE INDEX [IX_ShareCodes_AccessPolicy]
    ON [sharing].[ShareCodes] ([AccessPolicy]);
GO
